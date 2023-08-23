#pragma once

#include "../Object.h"

#include "helium/BaseArray.h"

namespace anari_mtl {

class Array : public helium::BaseArray {
private:
    AnariMetalGlobalState* state;

    const void* data;
    ANARIDataType dataType;
    uint3 dimensions;
    size_t elementCount;
    size_t size;

    std::vector<Object*> objects; //In case of object array
    bool checkedForObjects = false;

    size_t begin, end;

    //id mtlBuffer;

    void checkForObjects();

    void notifyObserver(BaseObject *o) const override {
        o->markUpdated();
        deviceState()->commitBuffer.addObject(o);
    }

public:
    Array(AnariMetalGlobalState* s, const void* aData, ANARIDataType aDataType, uint3 aDimensions);

    ~Array();

    void commit() override;

    const void* getData() {
        return /*(char*)*/data;// + begin;
    }

    void* getAtIndex(uint32_t index) {
        return (char*)getData() + index * anari::sizeOf(dataType);
    }

    template<typename T>
    T getAtIndexAs(uint32_t index) {
        return ((T*)getData())[index];
    }

    Object* getObjectAtIndex(uint32_t index) {
        return objects[index];
    }

    size_t getOffset() {
        return begin;
    }

    size_t getSize() {
        return size;//end - begin;
    }

    uint32_t getElementCount() {
        return elementCount;
    }

    const uint3 getDimensions() {
        return dimensions;
    }

    ANARIDataType getDataType() {
        return dataType;
    }

    AnariMetalGlobalState *deviceState() const {
        return state;
    }

    bool getProperty(const std::string_view &name, ANARIDataType type, void *ptr, uint32_t flags) override {
        return false;
    }

    void* map() override {
        return const_cast<void*>(data);
    }

    virtual void unmap() override {
        checkForObjects();
    }

    void privatize() override {
        //TODO
    }
};

} //namespace anari_mtl

ANARI_METAL_TYPEFOR_SPECIALIZATION(anari_mtl::Array*, ANARI_ARRAY);
