//
//  EUExZipMgr.h
//  webKitCorePalm
//
//  Created by AppCan on 11-9-7.
//  Copyright 2011 AppCan. All rights reserved.
//


#import "EUExBase.h"
#import "UexZipArchive.h"

@interface EUExZip : EUExBase {
    BOOL isZipWithPassword;
    BOOL isUnZipWithPassword;
    BOOL State;//用来判断压缩的zip宝是否是带密码的
}
@end
