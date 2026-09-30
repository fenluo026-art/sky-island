手机上传说明

这个压缩包已经整理好：
- 只有一个 GitHub Actions 工作流：.github/workflows/build.yml
- 不需要你自己创建 .github 或 workflows
- 不需要额外复制 android.yml
- APP：天空岛 Sky Island
- 包名：com.fenluo.skyisland
- 版本：1.0.0

手机操作：
1. 解压本压缩包。
2. 将里面的项目文件上传到 GitHub 仓库根目录。
3. 如果 GitHub 已经有旧文件，覆盖同名文件。
4. 确认仓库中只有一个 .github/workflows/build.yml。
5. 打开 Actions，运行 Build Android APK。

build.yml 会自动安装 Godot 4.4.1、Android SDK 和匹配的 Android Export Templates。
