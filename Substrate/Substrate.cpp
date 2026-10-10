#include "Substrate.h"

SIM_BEG;

using namespace bl;

/// ─────────────────────── project setup ───────────────────────

void Substrate_Project::UI::sidebar()
{
    bl_scoped(viewport_count);

    ImGui::SliderInt("Viewport Count", &viewport_count, 1, 8);
}

void Substrate_Project::projectPrepare(Layout& layout)
{
    for (int i = 0; i < viewport_count; i++)
        layout << create<Substrate_Scene>("substrate-" + std::to_string(i));
}

/// ────────────────────────── scene ──────────────────────────

void Substrate_Scene::UI::sidebar()
{
    if (ImGui::CollapsingHeaderBox("View", true))
    {
        bl_scoped(camera);

        camera.populateUI();
        ImGui::EndCollapsingHeaderBox();
    }

}

void Substrate_Scene::sceneStart()
{
    #ifdef BITLOOP_DEV_MODE
    diagnostic_ticks = 0;
    diagnostic_time_seconds = 0.0;
    #endif
}

void Substrate_Scene::sceneMounted([[maybe_unused]] Viewport* ctx)
{
    /// Initialize viewport.
    camera.setOriginViewportAnchor(Anchor::CENTER);
    // camera.focusWorldRect(*ctx, -100, -100, 100, 100);

    /// Enable reverting to the current camera view.
    camera.uiSetCurrentAsDefault();

    /// Configure default navigator.
    navigator.setTarget(camera);
    navigator.setDirectCameraPanning(true);
}

void Substrate_Scene::sceneUnmounted([[maybe_unused]] Viewport* ctx)
{
    /// Release state owned specifically for this Viewport.
}

void Substrate_Scene::sceneDestroy()
{
    /// Release dynamically allocated Scene resources.
}

void Substrate_Scene::sceneProcess()
{
    #ifdef BITLOOP_DEV_MODE
    ++diagnostic_ticks;
    // Bitloop frame_dt() is milliseconds; this is a lifecycle observable, not physical state.
    diagnostic_time_seconds += frame_dt() * 0.001;
    #endif

    // redraw the scene every frame
    requestRedraw(true);
}

void Substrate_Scene::viewportProcess(
    [[maybe_unused]] Viewport* ctx,
    [[maybe_unused]] double dt)
{
    /// Process one update for each mounted viewport every frame.
}

void Substrate_Scene::viewportDraw(Viewport* ctx) const
{
    /// Draw the Scene on this viewport without modifying simulation state.
    ctx->transform(camera);
    ctx->drawWorldAxis();

    #ifdef BITLOOP_DEV_MODE
    ctx->stageMode();
    ctx->setFillStyle(255, 255, 255);
    ctx->setFontSize(18);
    ctx->fillText("Diagnostic pilot - no physics", 20.0, 30.0);
    ctx->fillText("ticks = " + std::to_string(diagnostic_ticks), 20.0, 55.0);
    ctx->fillText("time (s) = " + std::to_string(diagnostic_time_seconds), 20.0, 80.0);
    #endif
}

void Substrate_Scene::onEvent(Event e)
{
    if (e.ownedBy(this))
        navigator.handleWorldNavigation(e, true);
}

// void Substrate_Scene::onPointerDown(PointerEvent e) {}
// void Substrate_Scene::onPointerUp(PointerEvent e) {}
// void Substrate_Scene::onPointerMove(PointerEvent e) {}
// void Substrate_Scene::onWheel(PointerEvent e) {}
// void Substrate_Scene::onKeyDown(KeyEvent e) {}
// void Substrate_Scene::onKeyUp(KeyEvent e) {}

#ifdef BITLOOP_DEV_MODE
void Substrate_Scene::traceFrame(SimTraceFrame& frame) const
{
    frame.metric("diagnostic_ticks", static_cast<double>(diagnostic_ticks));
    frame.metric("diagnostic_time_seconds", diagnostic_time_seconds);
    frame.metric("diagnostic_kind", "lifecycle_only_no_physics");
}

bool Substrate_Scene::saveCheckpoint([[maybe_unused]] SimCheckpointWriter& writer) const
{
    return false;
}

bool Substrate_Scene::loadCheckpoint([[maybe_unused]] const SimCheckpointReader& reader)
{
    return false;
}
#endif

SIM_END;
