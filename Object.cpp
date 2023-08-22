#include "Object.h"

//std
#include <atomic>
#include <cstdarg>

namespace anari_mtl {

// Object definitions /////////////////////////////////////////////////////////

Object::Object(ANARIDataType type, AnariMetalGlobalState *s)
    : helium::BaseObject(type, s)
{}

void Object::commit()
{
  // no-op
}

bool Object::getProperty(
    const std::string_view &name, ANARIDataType type, void *ptr, uint32_t flags)
{
  if (name == "valid" && type == ANARI_BOOL) {
    helium::writeToVoidP(ptr, isValid());
    return true;
  }

  return false;
}

bool Object::isValid() const
{
  return true;
}

AnariMetalGlobalState *Object::deviceState() const
{
  return (AnariMetalGlobalState*)helium::BaseObject::m_state;
}

// UnknownObject definitions //////////////////////////////////////////////////

UnknownObject::UnknownObject(ANARIDataType type, AnariMetalGlobalState *s)
    : Object(type, s)
{
  s->objectCounts.unknown++;
}

UnknownObject::~UnknownObject()
{
  deviceState()->objectCounts.unknown--;
}

bool UnknownObject::isValid() const
{
  return false;
}

} //namespace anari_mtl

ANARI_METAL_TYPEFOR_DEFINITION(anari_mtl::Object *);
