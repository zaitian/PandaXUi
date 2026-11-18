# PandaUi 前端

Vue3 + Vite4 + TypeScript + Element Plus 管理后台，对接 PandaX 后端。

## 命令

```powershell
npm install
npm run dev        # 7789；dev 下 /api 代理到 127.0.0.1:7788（vite.config.ts）
npm run build      # 产物输出 deploy/dist
npm run lint-fix   # eslint --fix
```

- 环境变量：`.env`（`VITE_PORT=7789`、`VITE_OPEN`、`VITE_PUBLIC_PATH`）、`.env.development`（`VITE_API_URL=http://127.0.0.1:7788` 以及大屏/规则/报表地址）、`.env.production`
- 没有单元测试，改动后要在浏览器实际验证（`http://127.0.0.1:7789`，admin/123456 + 验证码）

## 目录

```
src/
├── api/<模块>/*.ts        # 接口封装，按后端模块分组：system/device/log/job/rule/gen/tool/login/menu/resource
├── views/<模块>/          # 页面，列表页常见 index.vue + component/（editModule、view、xxx_info）
├── layout/                # 顶栏/侧边栏/标签页/锁屏等布局组件
├── router/                # createWebHashHistory；路由由后端菜单动态生成
├── stores/                # pinia：themeConfig、userInfos、routesList、tagsViewRoutes...
├── utils/                 # request.ts（axios）、storage.ts、formatTime.ts、authDirective.ts ...
├── theme/                 # scss 主题与媒体查询
└── i18n/                  # zh-cn / en
```

## 请求约定（`src/utils/request.ts`）

- 实例 `baseURL = VITE_API_URL`，请求头自动带 `X-TOKEN`（来自 `Session.get('token')`）
- 响应拦截：`code !== 200` 时 401/4001 清理登录态跳登录页，403/400 弹 `ElMessage.error(res.msg)`，其余仍返回 `response.data`
- 上传地址需手拼绝对路径：`import.meta.env.VITE_API_URL + "/upload/up/image"`，读取 `/upload/down/image/{file}`

## 页面写法（本项目既有风格）

```ts
import { reactive, onMounted, getCurrentInstance } from 'vue';
const { proxy } = getCurrentInstance() as any;
const state = reactive({ loading: true, tableData: [], queryParams: { pageNum: 1, pageSize: 10 }, modelForm: {} });
onMounted(() => {
  proxy.getDicts('sys_common_status').then((r: any) => (state.statusOptions = r.data));
  handleQuery();
});
```

- 字典：`proxy.getDicts(type)` + `proxy.selectDictLabel(options, value)`，不要硬编码中文枚举
- 列表页统一结构：查询区（el-form）→ 表格/卡片（el-table 或 `ft-card`）→ 分页（el-pagination）→ 编辑弹窗
- 按钮权限用 `v-auth="system:user:add"`（还有 `v-auths` 任一满足、`v-auth-all` 全部满足），权限来自 `/system/user/auth` 返回的 `authBtnList`
- 弹窗内表单用 `Ref` + `el-form` 校验；提交后 `ElMessage.success` 并刷新列表

## 本项目已定制的部分

- 操作日志详情（`src/views/log/operation/index.vue`）：`el-descriptions` 基本信息 + 「执行链路」时间轴（数据来自后端 `flow_data`）+ 可折叠 ASCII 流程图（`flow` 字段，带复制按钮）
- 设备管理（`src/views/device/device/index.vue`）：卡片式列表，分页每页 10 条；详情为右侧抽屉（设备详情/拓展信息/设备状态/告警/事件/命令），"设备状态" 内分「属性 / 遥测」
- 大屏/规则链/报表地址来自 `.env.development` 的 `VITE_SCREEN_URL`、`VITE_RULE_URL`、`VITE_REPORT_URL`

## 注意

- Element Plus 组件/图标按需引入；样式使用项目内的 scss 变量（`src/theme`），避免引入新 UI 库
- 单文件组件中 `<style>` 默认全局生效，给局部元素加类名前缀；需要覆盖 Element 内部类时用 `:deep()`
- 源码 UTF-8；PowerShell `Get-Content` 不加 `-Encoding UTF8` 会显示乱码，不要据此判断文件损坏
- 修改后先 `npm run dev`（热更新）在浏览器验证，再考虑 `npm run build`
