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

@interface EUExZip()
@property(nonatomic,strong) ACJSFunctionRef *func;
@end
@implementation EUExZip



-(void)dealloc{
	
}


-(void)zipThread:(NSMutableArray *)inArguments {
	NSString *inSrcPath = [inArguments objectAtIndex:0];
	NSString *inZippedPath = [inArguments objectAtIndex:1];
    NSString *inPassword = nil;
    if (isZipWithPassword) {
        inPassword = [NSString stringWithFormat:@"%@",[inArguments objectAtIndex:2]];
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
		UexZipArchive *zipObj = [[UexZipArchive alloc] init];
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
            
        }
		[zipObj CloseZipFile2];
        isZipWithPassword = NO;
		if ([fmanager fileExistsAtPath:trueZippedPath]) {
           //NSString *jsString = [NSString stringWithFormat:@"if(%@!=null){%@(%d,%d,%d);}",@"uexZip.cbZip",@"uexZip.cbZip", 0, UEX_CALLBACK_DATATYPE_INT, UEX_CSUCCESS];
            [self mainThreadCallBack:@"uexZip.cbZip" Function:self.func Param1:@0 Param2:@2 Param3:@0];

		}else {
           // NSString *jsString = [NSString stringWithFormat:@"if(%@!=null){%@(%d,%d,%d);}",@"uexZip.cbZip",@"uexZip.cbZip", 0, UEX_CALLBACK_DATATYPE_INT, UEX_CFAILED];
             [self mainThreadCallBack:@"uexZip.cbZip" Function:self.func Param1:@0 Param2:@2 Param3:@1];
		}
	}else{
        //NSString *inErrorDes =[UEX_ERROR_DESCRIBE_ARGS stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        //NSString *jsFailedStr = [NSString stringWithFormat:@"if(uexWidgetOne.cbError!=null){uexWidgetOne.cbError(%d,%d,\'%@\');}",0,1260101,inErrorDes];
        //[self mainThreadCallBack:jsFailedStr];
        
	}
    self.func = nil;
}

-(void)zipWithPassword:(NSMutableArray *)inArguments {
    if ([inArguments isKindOfClass:[NSMutableArray class]] && [inArguments count]>0) {
        isZipWithPassword = YES;
        [self zip:inArguments];
    }
}

-(void)zip:(NSMutableArray *)inArguments {
    ACJSFunctionRef *func = JSFunctionArg(inArguments.lastObject);
    self.func = func;
    [NSThread detachNewThreadSelector:@selector(zipThread:) toTarget:self withObject:inArguments];
}


-(void)unzipThread:(NSMutableArray *)inArguments {
    NSString *inSrcPath = [inArguments objectAtIndex:0];
    NSString *inunZippedPath = [inArguments objectAtIndex:1];
    NSString *inPassword = nil;
    
    if (isUnZipWithPassword) {
        if ([inArguments isKindOfClass:[NSMutableArray class]] && [inArguments count]>2) {
            inPassword = [NSString stringWithFormat:@"%@",[inArguments objectAtIndex:2]];
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
            UexZipArchive *zipObj = [[UexZipArchive alloc] init];
            if (isUnZipWithPassword) {
                ret = [zipObj UnzipOpenFile:trueSrcPath Password:inPassword];
            }else{
                //当state为yes 证明是带有密码的压缩包 需要使用 UnzipOpenFile Password 接口
                if (State) {
                    [zipObj UnzipCloseFile];
                    isUnZipWithPassword = NO;
                    NSError *error;
                    [fmanager removeItemAtPath:trueUnzippedPath error:&error];
                    
                    //NSString *jsString = [NSString stringWithFormat:@"if(%@!=null){%@(%d,%d,%d);}",@"uexZip.cbUnZip",@"uexZip.cbUnZip", 0, UEX_CALLBACK_DATATYPE_INT, UEX_CFAILED];
                    //[self mainThreadCallBack:jsString];
                    [self mainThreadCallBack:@"uexZip.cbUnZip" Function:self.func Param1:@0 Param2:@2 Param3:@1];

                    return;
                }else{
                    [zipObj UnzipOpenFile:trueSrcPath];
                }
            }
            ret = [zipObj UnzipFileTo:trueUnzippedPath overWrite:YES];
            [zipObj UnzipCloseFile];
        }
        isUnZipWithPassword = NO;
        if (ret) {
            //NSString *jsString = [NSString stringWithFormat:@"if(%@!=null){%@(%d,%d,%d);}",@"uexZip.cbUnZip",@"uexZip.cbUnZip", 0, UEX_CALLBACK_DATATYPE_INT, UEX_CSUCCESS];
            //[self mainThreadCallBack:jsString];
             [self mainThreadCallBack:@"uexZip.cbUnZip" Function:self.func Param1:@0 Param2:@2 Param3:@0];

        }else {
            NSError *error;
            [fmanager removeItemAtPath:trueUnzippedPath error:&error];
            
            //NSString *jsString = [NSString stringWithFormat:@"if(%@!=null){%@(%d,%d,%d);}",@"uexZip.cbUnZip",@"uexZip.cbUnZip", 0, UEX_CALLBACK_DATATYPE_INT, UEX_CFAILED];
            //[self mainThreadCallBack:jsString];
             [self mainThreadCallBack:@"uexZip.cbUnZip" Function:self.func Param1:@0 Param2:@2 Param3:@1];

        } 		
    }else{
//        NSString *inErrorDes =[UEX_ERROR_DESCRIBE_ARGS stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
//        NSString *jsFailedStr = [NSString stringWithFormat:@"if(uexWidgetOne.cbError!=null){uexWidgetOne.cbError(%d,%d,\'%@\');}",0,1260201,inErrorDes];
//        [self mainThreadCallBack:jsFailedStr];

    }
    self.func = nil;
}


-(void)unzip:(NSMutableArray *)inArguments {
    ACJSFunctionRef *func = JSFunctionArg(inArguments.lastObject);
    self.func = func;
    [NSThread detachNewThreadSelector:@selector(unzipThread:) toTarget:self withObject:inArguments];
}

-(void)unzipWithPassword:(NSMutableArray *)inArguments {
    
    if ([inArguments isKindOfClass:[NSMutableArray class]] && [inArguments count]>0) {
        isUnZipWithPassword = YES;
        [self unzip:inArguments];
    }
}

-(void)mainThreadCallBack:(NSString *)functionName Function:(ACJSFunctionRef*)func Param1:(NSNumber*)result1 Param2:(NSNumber*)result2 Param3:(NSNumber*)result3{
    if ([NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.webViewEngine callbackWithFunctionKeyPath:functionName arguments:ACArgsPack(result1,result2,result3)];
            [func executeWithArguments:ACArgsPack(result3)];
        });
    }else{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.webViewEngine callbackWithFunctionKeyPath:functionName arguments:ACArgsPack(result1,result2,result3)];
            [func executeWithArguments:ACArgsPack(result3)];
        });
       
    }
}

@end
