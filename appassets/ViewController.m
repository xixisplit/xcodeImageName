//
//  ViewController.m
//  appassets
//
//  Created by 陈曦1 on 2021/1/5.
//

#import "ViewController.h"
@interface ViewController()<NSControlTextEditingDelegate>
@property (nonatomic, strong) NSFileManager *fileManager;
@property (weak) IBOutlet NSTextField *filePathTextField;
@property (weak) IBOutlet NSProgressIndicator *progress;
@property (weak) IBOutlet NSProgressIndicator *transferProgress;

@property (nonatomic, strong) NSTextField *control;

@property (weak) IBOutlet NSTableView *tableview;
@property (weak) IBOutlet NSTextField *bundlePath;
@property (weak) IBOutlet NSButton *Image3X;
@property (weak) IBOutlet NSButton *Image2X;

@property (nonatomic, strong) NSMutableArray *logArray;
@property (nonatomic, strong) NSMutableArray *logtagArray;
@end
@implementation ViewController

- (void)viewDidLoad {
    self.fileManager = [NSFileManager defaultManager];
 
    self.tableview.dataSource = (id)self;
    self.tableview.delegate = (id)self;
    self.tableview.rowHeight = 40;
    self.logArray = [NSMutableArray array];
    self.logtagArray = [NSMutableArray array];
    [super viewDidLoad];
    [self configPathTextField];
    
    
    self.progress.hidden = YES;
    [self.progress stopAnimation:nil];
    self.transferProgress.hidden = YES;
    [self.transferProgress stopAnimation:nil];
    
    // Do any additional setup after loading the view.
}

-(void)configPathTextField{
    self.filePathTextField.delegate = (id)self;
    self.bundlePath.delegate = (id)self;

    NSString *path = [[NSUserDefaults standardUserDefaults] objectForKey:@"filePath"];
    if (path) {
        self.filePathTextField.stringValue = path;
    }
    {
        NSString *path = [[NSUserDefaults standardUserDefaults] objectForKey:@"filePath1"];
        if (path) {
            self.bundlePath.stringValue = path;
        }
    }
}

- (void)controlTextDidBeginEditing:(NSNotification *)obj{
    NSLog(@"%@-%@",[self class],NSStringFromSelector(_cmd));
}
- (void)controlTextDidEndEditing:(NSNotification *)obj{
    NSLog(@"%@-%@",[self class],NSStringFromSelector(_cmd));
    /**结束编辑的时候保存链接地址,方便下次启动使用*/
    [[NSUserDefaults standardUserDefaults] setObject:self.filePathTextField.stringValue forKey:@"filePath"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[NSUserDefaults standardUserDefaults] setObject:self.bundlePath.stringValue forKey:@"filePath1"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}
- (void)controlTextDidChange:(NSNotification *)obj{
    NSLog(@"%@-%@",[self class],NSStringFromSelector(_cmd));
}


- (IBAction)openFileClick:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.title = @"请选择 assets.xcassets 路径";
    panel.canChooseDirectories = YES;
    panel.canChooseFiles = YES;// 是否可以选择文件
    [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseOK) {
            self.filePathTextField.stringValue = panel.URL.path;
        }
    }];
}

- (IBAction)commitClick:(id)sender {
    
    [self.logArray removeAllObjects];
    [self.logtagArray removeAllObjects];
    
    if (self.filePathTextField.stringValue.length) {
        self.progress.hidden = NO;
        [self.progress startAnimation:nil];
        __block NSString *path = self.filePathTextField.stringValue;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self HandleFileWithPath:path fileName:@""];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progress stopAnimation:nil];
                self.progress.hidden = YES;
                
                NSAlert *alert = [[NSAlert alloc] init];
                alert.messageText = @"处理完成!";
                alert.alertStyle = NSAlertStyleInformational;
                [alert addButtonWithTitle:@"确认"];
                [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
                }];
                
            });
        });
    }else{
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"请选择 assets.xcassets 路径";
        alert.alertStyle = NSAlertStyleWarning;
        [alert addButtonWithTitle:@"确认"];
        [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {}];
    }
}


-(void)HandleFileWithPath:(NSString *)path fileName:(NSString *)fileName{
    NSArray* tempArray = [self.fileManager contentsOfDirectoryAtPath:path error:nil];
    //获取文件夹文件列表
    for (NSString *obj in tempArray) {
        if ([obj containsString:@".imageset"]) {
            NSString *imagesetPath = [path stringByAppendingFormat:@"/%@",obj];
            [self HandleFileWithPath:imagesetPath fileName:obj];
            NSLog(@"1");
        }else if ([obj containsString:@".png"] || [obj containsString:@".jpg"]){
            NSString *pngPath = [path stringByAppendingFormat:@"/%@",obj];
            NSString *s = @"@2x";
            if ([obj containsString:@"@2x"]) {
                s = @"@2x";
            }else if ([obj containsString:@"@3x"]){
                s = @"@3x";
            }
            // 这里开始处理文件名称替换
            NSString *pngFileName = [fileName stringByReplacingOccurrencesOfString:@".imageset" withString:@""];
            NSString *newPngPath = [path stringByAppendingFormat:@"/%@%@.png",pngFileName,s];
            if (![newPngPath isEqualToString:pngPath]) {
                NSError *error;
               BOOL rets = [self.fileManager moveItemAtPath:pngPath toPath:newPngPath error:&error];
                [self.logArray addObject:newPngPath];
                [self.logtagArray addObject:@(rets)];
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [self.tableview reloadData];
                    [self.tableview scrollRowToVisible:self.logArray.count-1];
                    
                });
                
            }
            NSLog(@"2");
        }else if ([obj containsString:@".json"]){

            if (fileName.length) {
                NSString *jsonPath = [path stringByAppendingFormat:@"/%@",obj];
                NSData *jsonData = [NSData dataWithContentsOfFile:jsonPath];
                NSMutableDictionary * jsonDict = [[NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:nil] mutableCopy];
                NSMutableString * str  =[[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] mutableCopy];
                
                NSMutableArray *images = [[jsonDict objectForKey:@"images"] mutableCopy];
                // 这里开始处理文件名称替换
                NSString *pngFileName = [fileName stringByReplacingOccurrencesOfString:@".imageset" withString:@""];
                for (int i = 0; i<images.count; i++) {
                    NSMutableDictionary *mutdict = [images[i] mutableCopy];
                    NSString *filename = mutdict[@"filename"];
                    NSString *scale = mutdict[@"scale"];
                    if (filename && scale) {
                        NSString *newFilename = [NSString stringWithFormat:@"%@@%@.png",pngFileName,scale];
                        if (![filename isEqualToString:newFilename]) {
                        [str replaceCharactersInRange:[str rangeOfString:filename] withString:newFilename];
                            NSLog(@"3.1");
                        }
                    }
                }
//                NSString *newPath = [jsonPath stringByReplacingOccurrencesOfString:@"Contents" withString:@"Contents"];
                NSString *newPath = jsonPath;
                NSError *error;
                [str writeToFile:newPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
            }
            
            NSLog(@"3");
        }else if(![obj containsString:@"."]){
            NSString *imagesetPath = [path stringByAppendingFormat:@"/%@",obj];
            [self HandleFileWithPath:imagesetPath fileName:nil];
        }
    }
}


-(void)modifyPhoto:(NSString *)path obj:(NSString *)obj type:(NSString *)type{

    
    
    
}

@end
@interface ViewController (tableView)<NSTableViewDelegate,NSTableViewDataSource>

@end
@implementation ViewController (tableView)

//选择.bundle 路径
- (IBAction)bundlePathTap:(id)sender {
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseFiles = YES;// 是否可以选择文件
    panel.title = @"请选择 bundle 路径";
    panel.canChooseDirectories = YES;// 是否可以选择文件夹
    [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseOK) {
            self.bundlePath.stringValue = panel.URL.path;
        }
    }];
    
    
}
//开始迁移
- (IBAction)startTransfer:(id)sender {
    [self.logArray removeAllObjects];
    [self.logtagArray removeAllObjects];
    
    if (self.filePathTextField.stringValue.length && self.bundlePath.stringValue.length) {
        self.transferProgress.hidden = NO;
        [self.transferProgress startAnimation:nil];
        __block NSString *path = self.filePathTextField.stringValue;
        __block NSString *bundlePath = self.bundlePath.stringValue;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self clearBundleFile:bundlePath];
            [self TransferWithFormPath:path toPath:bundlePath];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.transferProgress stopAnimation:nil];
                self.transferProgress.hidden = YES;
                
                NSAlert *alert = [[NSAlert alloc] init];
                alert.messageText = @"处理完成!";
                alert.alertStyle = NSAlertStyleInformational;
                [alert addButtonWithTitle:@"确认"];
                [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
                }];
                
            });
        });
    }else{
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"请选择 源文件路径 和 迁移目标路径";
        alert.alertStyle = NSAlertStyleWarning;
        [alert addButtonWithTitle:@"确认"];
        [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {}];
    }
}
-(void)clearBundleFile:(NSString *)bundlePath{
    NSArray *bundleNameArray = [self.fileManager contentsOfDirectoryAtPath:bundlePath error:nil];
    if (bundleNameArray.count) {
        for (NSString *path in bundleNameArray) {
            NSString *tempPath = [bundlePath stringByAppendingFormat:@"/%@",path];
            [self.fileManager removeItemAtPath:tempPath error:nil];
        }
    }
}
-(void)TransferWithFormPath:(NSString *)formPath toPath:(NSString *)toPath{
    
    NSArray* fileNameArray = [self.fileManager contentsOfDirectoryAtPath:formPath error:nil];
    
    for (int i = 0; i<fileNameArray.count; i++) {
        NSString *tmpPath = fileNameArray[i];
        NSString *filePath = [formPath stringByAppendingFormat:@"/%@",tmpPath];
        if ([tmpPath containsString:@".imageset"]) {
            NSString *fileToPath = [toPath stringByAppendingFormat:@"/%@",tmpPath];
            BOOL results = [self.fileManager copyItemAtPath:filePath toPath:fileToPath error:nil];
            //移除文件夹中的 json 文件.因为没用
            [self.fileManager removeItemAtPath:[fileToPath stringByAppendingString:@"/Contents.json"] error:nil];
            [self.logArray addObject:fileToPath];
            [self.logtagArray addObject:@(results)];
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self.tableview reloadData];
                [self.tableview scrollRowToVisible:self.logArray.count-1];
            });
        }else{
            [self TransferWithFormPath:filePath toPath:toPath];
        }
    }
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return self.logArray.count;
}


- (nullable NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row{
    
    if ([tableColumn.identifier isEqualToString: @"001"]) {
        
        NSTextField *field = [[NSTextField alloc] init];
        NSNumber *number = self.logtagArray[row];
        field.stringValue = [NSString stringWithFormat:@"%@_%@",@(row),number.stringValue];
        return field;
    }else{
        NSTextField *field = [[NSTextField alloc] init];
        field.stringValue = self.logArray[row];
        field.font = [NSFont menuFontOfSize:10];
        field.alignment = NSTextAlignmentRight;
        return field;
    }
}
@end
