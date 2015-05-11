//
//  EUExZipMgr.m
//  webKitCorePalm
//
//  Created by AppCan on 11-9-7.
//  Copyright 2011 AppCan. All rights reserved.
//

#import "EUExZip.h"
#import "EUtility.h"
 #import "EUExBaseDefine.h"

@implementation EUExZip

-(id)initWithBrwView:(EBrowserView *) eInBrwView{	
	if (self = [super initWithBrwView:eInBrwView]) {
	}
	return self;
}

-(void)dealloc{
	[super dealloc];
}


-(void)zip:(NSMutableArray *)inArguments {
	NSString *inSrcPath = [inArguments objectAtIndex:0];
	NSString *inZippedPath = [inArguments objectAtIndex:1];
    NSString *inPassword = nil;
    if (isZipWithPassword) {
        inPassword = [inArguments objectAtIndex:2];
    }
	BOOL ret = NO;
	NSString *trueSrcPath = [super absPath:inSrcPath];
	NSString *trueZippedPath = [super absPath:inZippedPath];
	if (trueSrcPath!=nil && trueZippedPath!=nil) {
 		NSFileManager *fmanager = [NSFileManager defaultManager];
		if ([fmanager fileExistsAtPath:trueZippedPath]) {
			[fmanager removeItemAtPath:trueZippedPath error:nil];
		} 
		//判断上级文件夹是否存在，不存在就创建
		NSString *docpath = [trueZippedPath substringToIndex:[trueZippedPath length]-([[trueZippedPath lastPathComponent] length])];
		if (![fmanager fileExistsAtPath:docpath]) {
			[fmanager createDirectoryAtPath:docpath withIntermediateDirectories:YES attributes:nil error:nil];
		}
        //12.29 zip
		ZipArchive *zipObj = [[ZipArchive alloc] init];
        if (isZipWithPassword) {
            State = isZipWithPassword;
            [zipObj CreateZipFile2:trueZippedPath Password:inPassword];
        }else{
            [zipObj CreateZipFile2:trueZippedPath];
        }
		NSArray *array= [trueSrcPath componentsSeparatedByString:@"/"];
		NSString *newName = [array lastObject];
        
        if ([newName length]!=0) {
            ret = [zipObj addFileToZip:trueSrcPath newname:newName];
        }else {
            NSDirectoryEnumerator *de = [[NSFileManager defaultManager] enumeratorAtPath:trueSrcPath];
            NSString *file = nil;
            while (file = [de nextObject]) {
                //判断文件 还是文件夹---07.17
                NSString *filePath;
                if (![trueSrcPath hasSuffix:@"/"]) {
                    filePath =[trueSrcPath stringByAppendingFormat:@"/%@",file];
                }else {
                    filePath =[trueSrcPath stringByAppendingString:file];
                }
                BOOL isDir;
                if ([[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDir] &&isDir) {
                }else {
                    [zipObj addFileToZip:filePath newname:file];
                }
            }  
        }
        if (ret) {
            //
        }
		[zipObj CloseZipFile2];
		[zipObj release];
        isZipWithPassword = NO;
		if ([fmanager fileExistsAtPath:trueZippedPath]) {
			[self jsSuccessWithName:@"uexZip.cbZip" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:UEX_CSUCCESS];
		}else {
			[self jsSuccessWithName:@"uexZip.cbZip" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:UEX_CFAILED];
		}
	}else{
		[self jsFailedWithOpId:0 errorCode:1260101 errorDes:UEX_ERROR_DESCRIBE_ARGS];
	}
}

-(void)zipWithPassword:(NSMutableArray *)inArguments {
    if ([inArguments isKindOfClass:[NSMutableArray class]] && [inArguments count]>0) {
        isZipWithPassword = YES;
        [self zip:inArguments];
    }
}

-(void)unzip:(NSMutableArray *)inArguments {
	NSString *inSrcPath = [inArguments objectAtIndex:0];
	NSString *inunZippedPath = [inArguments objectAtIndex:1];
    NSString *inPassword = nil;
    if (isUnZipWithPassword) {
        if ([inArguments isKindOfClass:[NSMutableArray class]] && [inArguments count]>2) {
            inPassword = [inArguments objectAtIndex:2];
        }
    }
    
	BOOL ret = NO;
	NSString *trueSrcPath = [super absPath:inSrcPath];
	NSString *trueUnzippedPath = [super absPath:inunZippedPath];
	if (trueSrcPath!=nil && trueUnzippedPath!=nil) {
		NSFileManager *fmanager = [NSFileManager defaultManager];
		if (![fmanager fileExistsAtPath:trueUnzippedPath]) {
			[fmanager createDirectoryAtPath:trueUnzippedPath withIntermediateDirectories:YES attributes:nil error:nil];
		}
		if ([fmanager fileExistsAtPath:trueSrcPath]) {
			ZipArchive *zipObj = [[ZipArchive alloc] init];
            if (isUnZipWithPassword) {
                [zipObj UnzipOpenFile:trueSrcPath Password:inPassword];
            }else{
                //当state为yes 证明是带有密码的压缩包 需要使用 UnzipOpenFile Password 接口
                if (State) {
                    [zipObj UnzipCloseFile];
                    [zipObj release];
                    isUnZipWithPassword = NO;
                    [self jsSuccessWithName:@"uexZip.cbUnZip" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:UEX_CFAILED];
                    return;
                }else{
                    [zipObj UnzipOpenFile:trueSrcPath];
                }
            }
			ret = [zipObj UnzipFileTo:trueUnzippedPath overWrite:YES];
			[zipObj UnzipCloseFile];
			[zipObj release];
		}
        isUnZipWithPassword = NO;
		if (ret) {
			[self jsSuccessWithName:@"uexZip.cbUnZip" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:UEX_CSUCCESS];
		}else {
			[self jsSuccessWithName:@"uexZip.cbUnZip" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:UEX_CFAILED];
		} 		
	}else{
		[self jsFailedWithOpId:0 errorCode:1260201 errorDes:UEX_ERROR_DESCRIBE_ARGS];
	}
}

-(void)unzipWithPassword:(NSMutableArray *)inArguments {
    if ([inArguments isKindOfClass:[NSMutableArray class]] && [inArguments count]>0) {
        isUnZipWithPassword = YES;
        [self unzip:inArguments];
    }
}

@end
