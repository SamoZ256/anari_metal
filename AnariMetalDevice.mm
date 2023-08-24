// Copyright 2022 The Khronos Group
// SPDX-License-Identifier: Apache-2.0

#include "AnariMetalDevice.h"

#include "frame/Frame.h"
//#include "array/ObjectArray.h"
//#include "frame/Frame.h"
//#include "scene/volume/spatial_field/SpatialField.h"

namespace anari_mtl {

///////////////////////////////////////////////////////////////////////////////
// Generated function declarations ////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

const char **query_object_types(ANARIDataType type);

const void *query_object_info(ANARIDataType type,
    const char *subtype,
    const char *infoName,
    ANARIDataType infoType);

const void *query_param_info(ANARIDataType type,
    const char *subtype,
    const char *paramName,
    ANARIDataType paramType,
    const char *infoName,
    ANARIDataType infoType);

const char **query_extensions();

///////////////////////////////////////////////////////////////////////////////
// Helper functions ///////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

template <typename HANDLE_T, typename OBJECT_T>
inline HANDLE_T getHandleForAPI(OBJECT_T *object)
{
  return (HANDLE_T)object;
}

template <typename OBJECT_T, typename HANDLE_T, typename... Args>
inline HANDLE_T createObjectForAPI(AnariMetalGlobalState *s, Args &&...args)
{
  return getHandleForAPI<HANDLE_T>(
      new OBJECT_T(s, std::forward<Args>(args)...));
}

///////////////////////////////////////////////////////////////////////////////
// AnariMetalDevice definitions ///////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

// Data Arrays ////////////////////////////////////////////////////////////////

ANARIArray1D AnariMetalDevice::newArray1D(const void *appMemory,
    ANARIMemoryDeleter deleter,
    const void *userData,
    ANARIDataType type,
    uint64_t numItems)
{
    initDevice();

    return createObjectForAPI<Array, ANARIArray1D>(deviceState(), appMemory, type, uint3(numItems, 1, 1));
}

ANARIArray2D AnariMetalDevice::newArray2D(const void *appMemory,
    ANARIMemoryDeleter deleter,
    const void *userData,
    ANARIDataType type,
    uint64_t numItems1,
    uint64_t numItems2)
{
    initDevice();

    return createObjectForAPI<Array, ANARIArray2D>(deviceState(), appMemory, type, uint3(numItems1, numItems2, 1));
}

ANARIArray3D AnariMetalDevice::newArray3D(const void *appMemory,
    ANARIMemoryDeleter deleter,
    const void *userData,
    ANARIDataType type,
    uint64_t numItems1,
    uint64_t numItems2,
    uint64_t numItems3)
{
    initDevice();

    return createObjectForAPI<Array, ANARIArray3D>(deviceState(), appMemory, type, uint3(numItems1, numItems2, numItems3));
}

// Renderable Objects /////////////////////////////////////////////////////////

ANARILight AnariMetalDevice::newLight(const char *subtype)
{
    initDevice();

    return getHandleForAPI<ANARILight>(Light::createInstance(subtype, deviceState()));
}

ANARICamera AnariMetalDevice::newCamera(const char *subtype)
{
    initDevice();

    return getHandleForAPI<ANARICamera>(Camera::createInstance(subtype, deviceState()));
}

ANARIGeometry AnariMetalDevice::newGeometry(const char *subtype)
{
    initDevice();

    return getHandleForAPI<ANARIGeometry>(Geometry::createInstance(subtype, deviceState()));
}

ANARISpatialField AnariMetalDevice::newSpatialField(const char *subtype)
{
    initDevice();

    return getHandleForAPI<ANARISpatialField>(SpatialField::createInstance(subtype, deviceState()));
}

ANARISurface AnariMetalDevice::newSurface()
{
    initDevice();

    return createObjectForAPI<Surface, ANARISurface>(deviceState());
}

ANARIVolume AnariMetalDevice::newVolume(const char *subtype)
{
    initDevice();

    return getHandleForAPI<ANARIVolume>(Volume::createInstance(subtype, deviceState()));
}

// Surface Meta-Data //////////////////////////////////////////////////////////

ANARIMaterial AnariMetalDevice::newMaterial(const char *subtype)
{
    initDevice();

    return getHandleForAPI<ANARIMaterial>(Material::createInstance(subtype, deviceState()));
}

ANARISampler AnariMetalDevice::newSampler(const char *subtype)
{
    initDevice();

    return getHandleForAPI<ANARISampler>(Sampler::createInstance(subtype, deviceState()));
}

// Instancing /////////////////////////////////////////////////////////////////

ANARIGroup AnariMetalDevice::newGroup()
{
    initDevice();

    return createObjectForAPI<Group, ANARIGroup>(deviceState());
}

ANARIInstance AnariMetalDevice::newInstance(const char * /*subtype*/)
{
    initDevice();

    return createObjectForAPI<Instance, ANARIInstance>(deviceState());
}

// Top-level Worlds ///////////////////////////////////////////////////////////

ANARIWorld AnariMetalDevice::newWorld()
{
    initDevice();

    return createObjectForAPI<World, ANARIWorld>(deviceState());
}

// Query functions ////////////////////////////////////////////////////////////

const char **AnariMetalDevice::getObjectSubtypes(ANARIDataType objectType)
{
    return anari_mtl::query_object_types(objectType);
}

const void *AnariMetalDevice::getObjectInfo(ANARIDataType objectType,
    const char *objectSubtype,
    const char *infoName,
    ANARIDataType infoType)
{
    return anari_mtl::query_object_info(objectType, objectSubtype, infoName, infoType);
}

const void *AnariMetalDevice::getParameterInfo(ANARIDataType objectType,
    const char *objectSubtype,
    const char *parameterName,
    ANARIDataType parameterType,
    const char *infoName,
    ANARIDataType infoType)
{
    return anari_mtl::query_param_info(objectType, objectSubtype, parameterName, parameterType, infoName, infoType);
}

// Object + Parameter Lifetime Management /////////////////////////////////////

int AnariMetalDevice::getProperty(ANARIObject object,
    const char *name,
    ANARIDataType type,
    void *mem,
    uint64_t size,
    uint32_t mask)
{
    if (handleIsDevice(object)) {
        std::string_view prop = name;
        if (prop == "feature" && type == ANARI_STRING_LIST) {
            helium::writeToVoidP(mem, query_extensions());
            return 1;
        } else if (prop == "anari_metal" && type == ANARI_BOOL) {
            helium::writeToVoidP(mem, true);
            return 1;
        }
    } else {
        if (mask == ANARI_WAIT) {
            deviceState()->waitOnCurrentFrame();
            flushCommitBuffer();
        }
        return helium::referenceFromHandle(object).getProperty(name, type, mem, mask);
    }

    return 0;
}

// Frame Manipulation /////////////////////////////////////////////////////////

ANARIFrame AnariMetalDevice::newFrame()
{
    initDevice();

    return createObjectForAPI<Frame, ANARIFrame>(deviceState());
}

// Frame Rendering ////////////////////////////////////////////////////////////

ANARIRenderer AnariMetalDevice::newRenderer(const char *subtype)
{
    initDevice();

    return getHandleForAPI<ANARIRenderer>(Renderer::createInstance(subtype, deviceState()));
}

// Other AnariMetalDevice definitions /////////////////////////////////////////////

AnariMetalDevice::AnariMetalDevice(ANARIStatusCallback cb, const void *ptr)
    : helium::BaseDevice(cb, ptr)
{
    m_state = std::make_unique<AnariMetalGlobalState>(this_device());
    deviceCommitParameters();
}

AnariMetalDevice::AnariMetalDevice(ANARILibrary l) : helium::BaseDevice(l)
{
    m_state = std::make_unique<AnariMetalGlobalState>(this_device());
    deviceCommitParameters();
}

AnariMetalDevice::~AnariMetalDevice()
{
    auto &state = *deviceState();

    state.commitBuffer.clear();

    reportMessage(ANARI_SEVERITY_DEBUG, "destroying helide device (%p)", this);

    auto reportLeaks = [&](size_t &count, const char *handleType) {
        if (count != 0) {
        reportMessage(ANARI_SEVERITY_WARNING,
            "detected %zu leaked %s objects",
            count,
            handleType);
        }
    };

    reportLeaks(state.objectCounts.frames, "ANARIFrame");
    reportLeaks(state.objectCounts.cameras, "ANARICamera");
    reportLeaks(state.objectCounts.renderers, "ANARIRenderer");
    reportLeaks(state.objectCounts.worlds, "ANARIWorld");
    reportLeaks(state.objectCounts.instances, "ANARIInstance");
    reportLeaks(state.objectCounts.groups, "ANARIGroup");
    reportLeaks(state.objectCounts.surfaces, "ANARISurface");
    reportLeaks(state.objectCounts.geometries, "ANARIGeometry");
    reportLeaks(state.objectCounts.materials, "ANARIMaterial");
    reportLeaks(state.objectCounts.samplers, "ANARISampler");
    reportLeaks(state.objectCounts.volumes, "ANARIVolume");
    reportLeaks(state.objectCounts.spatialFields, "ANARISpatialField");
    reportLeaks(state.objectCounts.arrays, "ANARIArray");

    if (state.objectCounts.unknown != 0) {
        reportMessage(ANARI_SEVERITY_WARNING,
            "detected %zu leaked ANARIObject objects created by unknown subtypes",
            state.objectCounts.unknown);
    }
}

void AnariMetalDevice::initDevice()
{
    if (m_initialized)
        return;

    reportMessage(ANARI_SEVERITY_DEBUG, "initializing anari_metal device (%p)", this);

    auto &state = *deviceState();

    state.mtlDevice = MTLCreateSystemDefaultDevice();
    if (!state.mtlDevice)
        reportMessage(ANARI_SEVERITY_ERROR, "failed to create MTLDevice");
    
    state.mtlCommandQueue = [state.mtlDevice newCommandQueue];
    if (!state.mtlCommandQueue)
        reportMessage(ANARI_SEVERITY_ERROR, "failed to create MTLCommandQueue");

    m_initialized = true;
}

void AnariMetalDevice::deviceCommitParameters()
{
    auto &state = *deviceState();

    bool allowInvalidSurfaceMaterials = state.allowInvalidSurfaceMaterials;

    state.allowInvalidSurfaceMaterials = getParam<bool>("allowInvalidMaterials", true);
    //TODO: uncomment
    //state.invalidMaterialColor = getParam<float4>("invalidMaterialColor", float4(1.f, 0.f, 1.f, 1.f));

    if (allowInvalidSurfaceMaterials != state.allowInvalidSurfaceMaterials)
        state.objectUpdates.lastBLSReconstructSceneRequest = helium::newTimeStamp();

    helium::BaseDevice::deviceCommitParameters();
}

AnariMetalGlobalState *AnariMetalDevice::deviceState() const
{
    return (AnariMetalGlobalState*)helium::BaseDevice::m_state.get();
}

} //namespace anari_mtl
