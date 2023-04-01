void Main() {
    startnew(CMapLoop);
}

void OnDestroyed() { Unload(); }
void OnDisabled() { Unload(); }
void Unload() { ResetManialinkToDefaults(); }
void OnEnabled() {
    try {
        AwaitGetMLObjs(); // can throw outside PG, just ignore
    } catch {}
 }

// note: we actually set frame-chrono to @MainMLFrame -- the child of Race_Chrono
const string MainMlFrameId = "frame-menu";

void CMapLoop() {
    auto app = cast<CGameManiaPlanet>(GetApp());
    auto net = app.Network;
    while (true) {
        yield();
        while (net.ClientManiaAppPlayground is null) yield();
        AwaitGetMLObjs();
        while (net.ClientManiaAppPlayground !is null) yield();
        @MainMLFrame = null;
        count = 0;
    }
}

CGameManialinkFrame@ MainMLFrame = null;

uint count = 0;
void AwaitGetMLObjs() {
    auto net = cast<CTrackManiaNetwork>(GetApp().Network);
    if (net.ClientManiaAppPlayground is null) throw('null cmap');
    auto cmap = net.ClientManiaAppPlayground;
    while (cmap.UILayers.Length < 7) yield();
    while (MainMLFrame is null) {
        yield();
        for (uint i = 0; i < cmap.UILayers.Length; i++) {
            auto layer = cmap.UILayers[i];
            if (!layer.IsLocalPageScriptRunning || !layer.IsVisible || layer.LocalPage is null) continue;
            // campaign menu
            auto frame = cast<CGameManialinkFrame>(layer.LocalPage.GetFirstChild(MainMlFrameId));
            if (frame !is null) {
                @MainMLFrame = frame;
                break;
            }
            // playmap menu
            auto innerF = layer.LocalPage.GetFirstChild("frame-button-list-pause-play-map");
            if (innerF !is null) {
                @MainMLFrame = innerF.Parent;
                break;
            }
        }
        count++;
        if (MainMLFrame is null && count < 10) trace('not found');
        if (count > 10) {
            warn('ML not found, not updating ML props');
            return;
        }
    }
    startnew(UpdateManialinkProps);
}

void UpdateManialinkProps() {
    if (MainMLFrame is null) throw('unexpected null MainMLFrame');
    MainMLFrame.RelativeScale = S_MenuScale;
    if (MainMLFrame.ControlId == "frame-global") {
        // if we're in PlayMap menu, then we need to upscale non-menu elements
        // controls: bg quad, menu top, helper labels, report, settings, credits, profile, buttons
        for (uint i = 0; i < MainMLFrame.Controls.Length; i++) {
            // skip menu bits, scale everything else up
            if (i == 1 || i == MainMLFrame.Controls.Length - 1) continue;
            MainMLFrame.Controls[i].RelativeScale = 1. / S_MenuScale;
        }
    }
}

void ResetManialinkToDefaults() {
    if (MainMLFrame is null) return;
    MainMLFrame.RelativeScale = 1.0;
    if (MainMLFrame.ControlId == "frame-global") {
        for (uint i = 0; i < MainMLFrame.Controls.Length; i++) {
            MainMLFrame.Controls[i].RelativeScale = 1.;
        }
    }
}

[Setting hidden]
float S_MenuScale = .9;

[SettingsTab name="General"]
void S_Render_General() {
    float orig = S_MenuScale;
    S_MenuScale = Math::Clamp(UI::InputFloat("Pause Menu Scale", S_MenuScale, 0.05), 0.05, 3.0);
    if (orig != S_MenuScale && MainMLFrame !is null) {
        UpdateManialinkProps();
    }
}
