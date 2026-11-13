# Titan Approx DPS 0.1.14-alpha

Results window now uses the native WoW controls instead of buttons.

## Changed

- Tabs are native panel tabs (PanelTabButtonTemplate, driven by PanelTemplates_SetNumTabs and PanelTemplates_SetTab) hanging below the window.
- Scope, category, period and the two Compare selectors are native drop-down boxes (DropdownButton with WowStyle1DropdownTemplate). They show the selected choice and open the native menu with one radio per option. A small light caption above each says what it filters.
- Search is the native search box (SearchBoxTemplate) with its placeholder text and clear control.
- Hidden weapons is a native check box (UICheckButtonTemplate).
- Scroll bars use the standard scroll bar knob texture and are 16 pixels wide.
- Every control keeps a fallback: if the client lacks a native template the window uses the previous button-based controls instead of failing to open. The tests cover both the native and the fallback path.
- With native tabs the filters move up to use the freed space.

## Limits

- Sizes and spacing need in-game verification.
