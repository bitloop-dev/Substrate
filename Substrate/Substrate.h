#pragma once
#include <bitloop.h>

SIM_BEG;

using namespace bl;

struct Substrate_Scene : public Scene<Substrate_Scene>
{
    CameraInfo       camera;
    CameraNavigator  navigator;

    /// ─────── Variables ───────


    /// ─────── Methods ───────


    /// ─────── Launch config ───────
    struct Config {};

    Substrate_Scene(Config& info [[maybe_unused]])
    {}

    struct UI : BufferedInterfaceModel
    {
        using BufferedInterfaceModel::BufferedInterfaceModel;
        void sidebar() override;
        // void overlay() override; // ImGui viewport overlay

        /// ─────── Your UI-only variables ───────

    };

    /// ─────── Scene methods ───────
    void sceneStart() override;
    void sceneMounted(Viewport* viewport) override;
    void sceneUnmounted(Viewport* viewport) override;
    void sceneDestroy() override;
    void sceneProcess() override;

    /// ─────── Viewport methods ───────
    void viewportProcess(Viewport* ctx, double dt) override;
    void viewportDraw(Viewport* ctx) const override;

    /// ─────── Input handling ───────
    void onEvent(Event e) override; // receives all event types


    // ─────── AI hooks ───────
    #ifdef BITLOOP_DEV_MODE
    std::uint64_t diagnostic_ticks = 0;
    double diagnostic_time_seconds = 0.0;

    void traceFrame(SimTraceFrame& frame) const override;
    bool saveCheckpoint(SimCheckpointWriter& writer) const override;
    bool loadCheckpoint(const SimCheckpointReader& reader) override;
    #endif
};

struct Substrate_Project : public Project<Substrate_Project>
{
    static ProjectInfo info()
    {
        return ProjectInfo({ "New Projects", "Substrate" });
    }

    struct UI : BufferedInterfaceModel
    {
        using BufferedInterfaceModel::BufferedInterfaceModel;
        void sidebar();
        // void overlay();
    };

    int viewport_count = 1;

    void projectPrepare(Layout& layout) override;
};

SIM_END;
