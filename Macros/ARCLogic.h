//
//  ARCLogic.h
//	

#ifndef ARCLOGIC
#define ARCLOGIC

#ifdef HASARC
#undef HASARC
#endif
#ifdef HASWEAK
#undef HASWEAK
#endif
#ifdef STRONG
#undef STRONG
#endif
#ifdef WEAK
#undef WEAK
#endif
#ifdef __WEAK
#undef __WEAK
#endif

#if __has_feature(objc_arc)
#define HASARC 1
#else
#define HASARC 0
#endif

#if __has_feature(objc_arc_weak)
#define HASWEAK 1
#else
#define HASWEAK 0
#endif

#if HASARC
#define IF_ARC(ARCBlock) ARCBlock
#define NO_ARC(NoARCBlock) 
#define STRONG strong
#define __STRONG __strong
#if HASWEAK
#define __WEAK __weak
#define WEAK weak
#define NO_WEAK(NoWeakBlock) 
#else
#define WEAK assign
#define __WEAK 
#define NO_WEAK(NoWeakBlock) NoWeakBlock
#endif
#else
#define IF_ARC(ARCBlock) 
#define NO_ARC(NoARCBlock) NoARCBlock
#define STRONG retain
#define __STRONG 
#define WEAK assign
#define __WEAK 
#define NO_WEAK(NoWeakBlock) NoWeakBlock
#endif

#endif
