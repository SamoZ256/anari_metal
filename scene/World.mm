#include "World.h"

#include "metal_helper/MetalHelper.h"

namespace anari_mtl {

//TODO: move this to metal helper
id<MTLArgumentEncoder> createArgumentEncoder(id device, NSMutableArray<id <MTLResource>>* resources) {
    NSMutableArray* arguments = [NSMutableArray array];

    for (id<MTLResource> resource in resources) {
        MTLArgumentDescriptor* argumentDescriptor = [MTLArgumentDescriptor argumentDescriptor];

        argumentDescriptor.index = arguments.count;
        argumentDescriptor.access = MTLArgumentAccessReadOnly;

        if ([resource conformsToProtocol:@protocol(MTLBuffer)])
            argumentDescriptor.dataType = MTLDataTypePointer;
        else if ([resource conformsToProtocol:@protocol(MTLTexture)]) {
            id <MTLTexture> texture = (id <MTLTexture>)resource;

            argumentDescriptor.dataType = MTLDataTypeTexture;
            argumentDescriptor.textureType = texture.textureType;
        }

        [arguments addObject:argumentDescriptor];
    }

    return [device newArgumentEncoderWithArguments:arguments];
}

World::World(AnariMetalGlobalState* s) : Object(ANARI_WORLD, s) {
    s->objectCounts.worlds++;

    //TODO: initialize
}

World::~World() {
    //TODO: do cleanup
    deviceState()->objectCounts.worlds--;
}

bool World::getProperty(const std::string_view &name, ANARIDataType type, void *ptr, uint32_t flags) {
    if (name == "bounds" && type == ANARI_FLOAT32_BOX3) {
        if (flags & ANARI_WAIT) {
            deviceState()->waitOnCurrentFrame();
            deviceState()->commitBuffer.flush();
        }
        memcpy(ptr, &bounds, sizeof(bounds));
        
        return true;
    }

  return Object::getProperty(name, type, ptr, flags);
}

void World::commit() {
    instances = getParamObject<Array>("instance");
    surfaces = getParamObject<Array>("surface");
    lights = getParamObject<Array>("light");

    //Get the bounds
    if (instances) {
        for (uint32_t i = 0; i < instances->getElementCount(); i++) {
            Bounds crntBounds = instances->getObjectAtIndex(i)->getBounds(identity);
            bounds.min = min(bounds.min, crntBounds.min);
            bounds.max = max(bounds.max, crntBounds.max);
        }
    }
    if (surfaces) {
        for (uint32_t i = 0; i < surfaces->getElementCount(); i++) {
            Bounds crntBounds = surfaces->getObjectAtIndex(i)->getBounds(identity);
            bounds.min = min(bounds.min, crntBounds.min);
            bounds.max = max(bounds.max, crntBounds.max);
        }
    }
}

void World::buildAccelerationStructure() {
    if (!builtAccelerationStructure) {
        // ---------------- Acceleration structure ----------------
        std::vector<Surface*> allSurfaces;
        //TODO: fill it in the buildAccelerationStructureAndAddGeometryToList method instead
        if (surfaces) {
            for (uint32_t i = 0; i < surfaces->getElementCount(); i++)
                allSurfaces.push_back(dynamic_cast<Surface*>(surfaces->getObjectAtIndex(i)));
        }
        NSMutableArray* primitiveAccelerationStructures = [[NSMutableArray alloc] init];

        size_t instanceCount = 0;//(instances ? instances->getElementCount() : 0);
        size_t surfaceCount = (surfaces ? surfaces->getElementCount() : 0);
        size_t instanceDescriptorCount = instanceCount + surfaceCount;

        instanceBuffer = [deviceState()->mtlDevice newBufferWithLength:sizeof(MTLAccelerationStructureInstanceDescriptor) * instanceDescriptorCount options:MTLResourceStorageModeShared];
        MTLAccelerationStructureInstanceDescriptor* instanceDescriptors = (MTLAccelerationStructureInstanceDescriptor*)((id<MTLBuffer>)instanceBuffer).contents;

        if (instances) {
            for (uint32_t i = 0; i < instances->getElementCount(); i++) {
                Instance* instance = dynamic_cast<Instance*>(instances->getObjectAtIndex(i));
                instance->buildAccelerationStructureAndAddGeometryToList(primitiveAccelerationStructures);
                instance->createInstanceAccelerationStructureDescriptor(&instanceDescriptors[i]);
            }
        }
        if (surfaces) {
            for (uint32_t i = 0; i < surfaces->getElementCount(); i++) {
                Surface* surface = dynamic_cast<Surface*>(surfaces->getObjectAtIndex(i));
                surface->buildAccelerationStructureAndAddGeometryToList(primitiveAccelerationStructures);
                surface->createInstanceAccelerationStructureDescriptor(&instanceDescriptors[instanceCount + i]);
            }
        }

        MTLInstanceAccelerationStructureDescriptor* accelDescriptor = [MTLInstanceAccelerationStructureDescriptor descriptor];
        accelDescriptor.instancedAccelerationStructures = primitiveAccelerationStructures;
        accelDescriptor.instanceCount = instanceDescriptorCount;
        accelDescriptor.instanceDescriptorBuffer = instanceBuffer;

        instanceAccelerationStructure = helper::buildAccelerationStructure(deviceState()->mtlDevice, deviceState()->mtlCommandQueue, accelDescriptor);

        // ---------------- Resources buffer ----------------
        size_t resourcesStride = 0;
        for (uint32_t geometryIndex = 0; geometryIndex < allSurfaces.size(); geometryIndex++) {
            Surface* surface = allSurfaces[geometryIndex];
            id <MTLArgumentEncoder> encoder = createArgumentEncoder(deviceState()->mtlDevice, surface->getResources());

            if (encoder.encodedLength > resourcesStride)
                resourcesStride = encoder.encodedLength;
        }
        size_t allResourcesStride = resourcesStride;// + sizeof(float4) + sizeof(bool);

        //TODO: use private storage mode
        resourcesBuffer = [deviceState()->mtlDevice newBufferWithLength:allResourcesStride * allSurfaces.size() options:MTLResourceStorageModeShared];

        for (uint32_t geometryIndex = 0; geometryIndex < allSurfaces.size(); geometryIndex++) {
            Surface* surface = allSurfaces[geometryIndex];

            //char* aditionalResources = (char*)[resourcesBuffer contents] + geometryIndex * allResourcesStride + resourcesStride;
            NSMutableArray<id<MTLResource>>* resources = surface->getResources(/*(float4*)aditionalResources, (bool*)(aditionalResources + sizeof(float4))*/);
            id <MTLArgumentEncoder> encoder = createArgumentEncoder(deviceState()->mtlDevice, resources);

            [encoder setArgumentBuffer:resourcesBuffer offset:geometryIndex * allResourcesStride];

            for (uint8_t i = 0; i < [resources count]; i++) {
                if ([resources[i] conformsToProtocol:@protocol(MTLBuffer)])
                    [encoder setBuffer:(id<MTLBuffer>)resources[i] offset:0 atIndex:i];
                else if ([resources[i] conformsToProtocol:@protocol(MTLTexture)])
                    [encoder setTexture:(id<MTLTexture>)resources[i] atIndex:i];
            }
        }

        builtAccelerationStructure = true;
    }
}

} //namespace anari_mtl

ANARI_METAL_TYPEFOR_DEFINITION(anari_mtl::World*);
