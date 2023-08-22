#include "Array.h"

namespace anari_mtl {

void objRefInc(Object* object) {
    if (object)
        object->refInc(helium::INTERNAL);
}

void objRefDec(Object* object) {
    if (object)
        object->refDec(helium::INTERNAL);
}

//TODO: use different type than @ref ANARI_ARRAY?
Array::Array(AnariMetalGlobalState* s, const void* aData, ANARIDataType aDataType, uint3 aDimensions) : helium::BaseArray(ANARI_ARRAY, s), state(s), data(aData), dataType(aDataType), dimensions(aDimensions), elementCount(dimensions.x * dimensions.y * dimensions.z) {
    s->objectCounts.arrays++;

    size = anari::sizeOf(dataType) * elementCount;
    if (!data)
        data = malloc(size);
    else
        checkForObjects();

    //Set begin and end
    begin = 0;
    end = size;
}

Array::~Array() {
    //TODO: take begin and end into account
    for (auto* object : objects)
        objRefDec(object);
    deviceState()->objectCounts.arrays--;
}

void Array::commit() {
    begin = getParam<size_t>("begin", 0);
    begin = std::clamp(begin, size_t(0), elementCount - 1);
    end = getParam<size_t>("end", elementCount);
    end = std::clamp(end, size_t(1), elementCount);

    //TODO: notify observers if changed
}

void Array::checkForObjects() {
    if (!checkedForObjects && anari::isObject(dataType)) {
        objects.resize(elementCount);
        memcpy(objects.data(), data, size);
        for (auto* object : objects)
            objRefInc(object);

        checkedForObjects = true;
    }
}

} //namespace anari_mtl
