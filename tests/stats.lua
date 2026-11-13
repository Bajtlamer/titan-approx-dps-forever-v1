local ns={}
for _,f in ipairs({'Namespace','Capabilities','Settings','Storage','SpellRules','WeaponAttribution','Records','Categories','Stats','Reports','Json','BuildSnapshot','Transfer'})do assert(loadfile('TitanApproxDPS/'..f..'.lua'))('x',ns)end
local S=ns.Stats
local function near(a,b)return math.abs(a-b)<1e-9 end
-- weighted running mean and merge
local a=S.New();S.Add(a,10,10);S.Add(a,30,30)
assert(a.n==2 and near(a.mean,25),'weighted mean')
local x,y,whole=S.New(),S.New(),S.New()
for i,v in ipairs({{10,10},{30,30},{20,12},{50,40}})do S.Add(whole,v[1],v[2]);S.Add(i<=2 and x or y,v[1],v[2])end
local m=S.Merge(x,y);assert(m.n==whole.n and near(m.mean,whole.mean) and near(m.s,whole.s) and near(m.weight,whole.weight),'merge equals whole')
-- summary
local empty=S.Summary(S.New());assert(empty.n==0 and empty.typical==nil and empty.confidence=='none')
assert(S.Summary(a).confidence=='low')
local many=S.New();for i=1,12 do S.Add(many,100+(i%2),10)end;assert(S.Summary(many).confidence=='medium')
local tight=S.New();for i=1,30 do S.Add(tight,100+(i%2),10)end;local ts=S.Summary(tight);assert(ts.confidence=='high' and ts.spread<0.1,'high confidence')
local noisy=S.New();for i=1,30 do S.Add(noisy,i%2==0 and 10 or 190,10)end;assert(S.Summary(noisy).confidence=='medium','noisy never high')
assert(S.Summary(a,{1,2,3}).recentMedian==2 and S.Summary(a,{1,2,3,4}).recentMedian==2.5,'median')

-- store integration
local PROFILE='16:empty;17:empty;18:20:0'
local KEY='slot:18:20:0'
local function newStore()local db=ns.Storage.Open({},'p');db:Character().class='HUNTER';return db end
local function fight(db,id,damage,seconds,mode)
 db:UpsertContribution({receiptID=id,profile=PROFILE,mode=mode or 'pve',damage=damage,seconds=seconds,spells={{spellID=75,origin='player',damage={value=damage}}}})
end
local function get(db,mode,scope)return S.ForGroup(S.Collect(db:Character()),KEY,mode or 'all',scope or 'lifetime')end
local db=newStore()
fight(db,'a',100,10);fight(db,'b',600,20)
local s=get(db);assert(s.n==2 and near(s.typical,(10*10+30*20)/30),'typical dps from fights')
-- revisions of the same session never double count
fight(db,'b',600,20);fight(db,'b',600,20);assert(get(db).n==2,'revision double counted')
-- a revised session replaces its sample
fight(db,'b',1000,20);assert(near(get(db).typical,(10*10+50*20)/30),'revision not replaced')
-- short and unknown duration fights give no sample
fight(db,'short',999,5);fight(db,'unknown',999,nil);assert(get(db).n==2,'short fights must not be sampled')
-- modes are separate, all merges
fight(db,'p',200,10,'pvp');assert(get(db,'pvp').n==1 and near(get(db,'pvp').typical,20) and get(db,'pve').n==2 and get(db,'all').n==3)
-- fresh reports reset the period only
db:ResetReports(1)
assert(get(db,'all','period').n==0 and get(db,'all','lifetime').n==3,'period reset must keep lifetime')
fight(db,'new',300,10);assert(get(db,'all','period').n==1 and get(db,'all','lifetime').n==4)
-- improves with use: typical converges as fights accumulate
local c=newStore();for i=1,40 do fight(c,'f'..i,(i%2==0 and 90 or 110)*10,10)end
local conv=get(c);assert(conv.n==40 and near(conv.typical,100) and conv.confidence=='high','converged')
-- recent window is the last 20 fights, newest by capture order
local r=newStore();for i=1,25 do fight(r,'r'..i,i*100,10)end
assert(near(get(r).recentMedian,155),"recent median of fights 6..25")
-- retirement folds old fights into the protected base without losing samples
local big=newStore();for i=1,2050 do fight(big,'x'..i,100,10)end
assert(get(big).n==2050 and near(get(big).typical,10),'retired samples kept')
assert(ns.Stats.ValidateBase(big:Character().baseStats))
-- report integration
local rep=ns.Reports.Build(db,'all');local g;for _,x in ipairs(rep.groups)do if x.profile==KEY then g=x end end
assert(g and g.kind=='ranged' and g.stats and g.stats.lifetime.n==4 and g.stats.period.n==1,'report carries kind and stats')
-- transfer keeps base stats and rejects malformed ones
local snapshot=ns.Transfer.Export(big);local target=newStore()
local p=assert(ns.Transfer.Stage(snapshot,target));assert(ns.Transfer.Apply(p,target));assert(get(target).n==2050,'imported base stats')
local doc=ns.Json.Decode(snapshot);doc.data.baseStats[next(doc.data.baseStats)]=7
assert(not ns.Transfer.Stage(ns.Json.Encode(doc),newStore()),'malformed base stats accepted')
assert(not S.ValidateBase({[KEY]={pve={n=-1,mean=1,s=0,weight=1}}}))
print('PASS running statistics: weighted, revision-safe, per mode, period reset, recent window, retirement, transfer')
