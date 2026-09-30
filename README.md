# Sky Island / 天穹之境

这是一个精简的 Godot 4.4.1 手机工程。

## 当前工程内容

- 程序化地表 Chunk
- 基础山丘
- 湖泊
- Godot 4.4.1 / GL Compatibility
- Android ARM64 导出
- 固定 application id：`com.fenluo.skyisland`
- 当前版本：1.1.2

## 说明

80,000 km² 是世界逻辑目标面积，不把 80,000 km² 的全部美术资源一次性塞进 APK。
当前工程先保证底层项目能够正确解析、导出和运行；后续大型地形、城市、建筑、生态和地下设施继续接入 Chunk / LOD。

## Android

后续 APK 使用相同 application id，并递增 version code / version name。
如果签名密钥发生变化，Android 不能直接覆盖安装旧签名 APK。
