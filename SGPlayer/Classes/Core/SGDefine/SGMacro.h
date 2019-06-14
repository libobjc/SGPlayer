//
//  SGMacro.h
//  SGPlayer
//
//  Created by Single on 16/6/29.
//  Copyright © 2016年 single. All rights reserved.
//

#ifndef SGMacro_h
#define SGMacro_h

#import <Foundation/Foundation.h>

#define SGWeakify(obj) __weak typeof(obj) weak_obj = obj;
#define SGStrongify(obj) __strong typeof(weak_obj) obj = weak_obj;

#ifdef DEBUG
#define SGPlayerLog(...) NSLog(__VA_ARGS__)
#else
#define SGPlayerLog(...)
#endif

#define SGGet0Map(ret, name0, obj) - (ret)name0 {return obj.name0;}
#define SGGet1Map(ret, name0, t0, obj) - (ret)name0:(t0)n0 {return [obj name0:n0];}
#define SGGet00Map(ret, name0, name00, obj) - (ret)name0 {return obj.name00;}
#define SGGet11Map(ret, name0, name00, t0, obj) - (ret)name0:(t0)n0 {return [obj name00:n0];}

#define SGSet1Map(ret, name0, t0, obj) - (ret)name0:(t0)n0 {[obj name0:n0];}
#define SGSet2Map(ret, name0, t0, name1, t1, obj) - (ret)name0:(t0)n0 name1:(t1)n1 {[obj name0:n0 name1:n1];}
#define SGSet11Map(ret, name0, name00, t0, obj) - (ret)name0:(t0)n0 {[obj name00:n0];}
#define SGSet22Map(ret, name0, name00, t0, name1, name11, t1, obj) - (ret)name0:(t0)n0 name1:(t1)n1 {[obj name00:n0 name11:n1];}

#endif
