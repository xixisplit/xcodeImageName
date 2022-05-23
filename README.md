# xcodeImageName

<img width="480" alt="image" src="https://user-images.githubusercontent.com/17351286/169740698-b800b572-72ae-42af-b12f-32c2100f93fe.png">

Xcode项目的.xcassets 图片资源一键修改命名,将xcassets资源一键转移到.bundle中
仅限企业包分发,此压缩方式可缩减包体积30%左右,具体看项目而定



1.开发阶段.将新增的图片放入 images.xcassets 中,正常开发.使用 UIImageNameMake() 来创建UIImage 对象

2.测试打包阶段. images.xcassets 的 Target Membership 勾选需要的项目 target 正常打包即可.测试包的体积会较大.是正常现象

3.发布打包阶段.(下方为手动方式,可参考截图.使用工具自动转移)

3.1在 images.xcassets 文件夹中.指定当前文件夹 搜索 .imagesets 会显示出所有的 .imagesets 后缀的文件夹.将这些文件夹全选.然后复制.

3.2将 images.bundle 中的所有文件夹清空

3.3将 复制的文件夹 全部粘贴到 images.bundle 中

3.4将 images.xcassets 的 Target Membership 所有引用全部取消.防止将这个文件夹打包到 ipa 包

3.5编译,打包


1.将 images.xcassets 文件夹中的所有图片.不包含分组分文件夹, 包含.png的外部文件夹.直接复制到 images.bundle 中
所有 image 的初始化方法.使用 UIImageNameMake()来获取.在内部如果普通方式获取不到.会到images.bundle中来找


#define UIImageNameMake(img) [UIImage imageNamedMake:img func:NSStringFromSelector(_cmd) line:__LINE__]
+(UIImage *)imageNamedMake:(NSString *)name{
    return [UIImage imageNamedMake:name func:nil line:0];
}

+ (UIImage *)imageNamedMake:(NSString *)name func:(NSString *)func line:(int)line{
    UIImage *image;
    
    image = [UIImage imageNamed:name];
    if (!image) {
        NSString *imageName = [NSString stringWithFormat:@"images.bundle/%@.imageset/%@",name,name];
        image = [UIImage imageNamed:imageName];
    }

    {
#if DEBUG
        NSAssert(image, @"没有找到对应的图片资源_(%@),所在方法:%@,行:%d",name,func,line);
#endif
    }
    return image;
}
