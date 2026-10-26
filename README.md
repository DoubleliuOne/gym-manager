# 健身房会员管理系统 (Gym Manager)

一套面向健身房运营的会员管理系统，包含后台管理端（Vue 3）与会员端（HarmonyOS 原生应用），后端由 Spring Boot 3 提供 REST API，数据落在 openGauss / PostgreSQL。

## 功能概览

**管理端（Web）**

- 数据看板：会员、营收、课程等经营指标统计
- 会员管理：会员档案、会员详情、状态维护
- 会员卡管理：卡种模板配置、开卡、续费记录
- 教练管理：教练档案与排课关联
- 课程与排期：课程维护、课程排期发布
- 预约管理：预约记录与签到核销

**会员端（HarmonyOS App）**

- 注册 / 登录、个人资料设置
- 首页、教练列表、课程浏览
- 会员卡购买与我的会员卡

## 技术栈

| 层次 | 技术 |
| --- | --- |
| 后端 | Java 17、Spring Boot 3.2、MyBatis-Plus 3.5、JWT (auth0 java-jwt) |
| 数据库 | openGauss 5.x / PostgreSQL（JDBC 兼容驱动） |
| 管理端 | Vue 3.5、TypeScript、Vite 6、Pinia、Vue Router、Ant Design Vue 4 |
| 会员端 | HarmonyOS ArkTS（DevEco Studio 工程） |

## 目录结构

```text
backend/        Spring Boot 后端服务（com.gym.*，按业务域分包）
frontend-vue/   Vue 3 管理端
harmony/        HarmonyOS 会员端（DevEco Studio 工程）
sql/            数据库建表脚本
scripts/        辅助脚本
```

## 快速开始

### 1. 初始化数据库

```bash
psql -h localhost -p 5432 -U gaussdb -d postgres -f sql/01-schema.sql
```

主要数据表：`member`、`card_template`、`member_card`、`renewal_record`、`coach`、`course`、`course_schedule`、`booking`、`check_in`。

### 2. 启动后端

```bash
cd backend
mvn spring-boot:run
```

服务默认监听 `http://localhost:8080`。数据库连接、JWT 密钥等配置见 `backend/src/main/resources/application.yml`，可通过环境变量覆盖：

数据库口令和 JWT 密钥不写在仓库里，而是放在被忽略的 `application-local.yml` 中。首次运行前：

```bash
cd backend/src/main/resources
cp application-local.yml.example application-local.yml
# 编辑 application-local.yml，填入你自己的数据库口令与 JWT 密钥
```

后端默认激活 `local` profile，复制好即可直接启动。也可以改用环境变量注入：

```bash
export DB_URL="jdbc:postgresql://localhost:5432/postgres?currentSchema=public"
export DB_USERNAME=gaussdb
export DB_PASSWORD=your-password
export JWT_SECRET=your-jwt-secret
```

### 3. 启动管理端

```bash
cd frontend-vue
npm install
npm run dev
```

### 4. 运行会员端

用 DevEco Studio 打开 `harmony/` 目录，配置签名后在模拟器或真机上运行。API 地址在 `harmony/entry/src/main/ets/utils/HttpUtil.ets` 中调整。

## 安全说明

`application.yml` 只保留占位符，真实口令与密钥通过 `application-local.yml` 或环境变量注入，`application-local.yml` 已被 `.gitignore` 忽略。部署到公网前请更换数据库口令与 JWT 密钥。

`AdminInitializer` 在首次启动时会创建一个演示用管理员账号（手机号 `18800000000`，初始口令 `admin123`），生产环境请移除或立即改密。

## License

本项目用于课程实训，未指定开源许可证。
