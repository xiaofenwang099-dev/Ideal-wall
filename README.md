# 理想收集所

温柔明亮的理想墙，支持注册登录、公开或私密投稿、个人心愿管理、分类筛选、热门排序、气球与列表视图、已完成梦想页、点赞，以及管理员管理。

## 本地预览

无需构建工具。使用现代浏览器打开 `index.html`，或运行：

```sh
python -m http.server 8000
```

然后访问 http://localhost:8000。未配置 Supabase 时，页面使用示例数据和浏览器 `localStorage`，只在当前设备有效；本地演示模式不提供真实账户。

## 线上功能与数据库

页面使用 Supabase Postgres、Auth 和 Row Level Security。访客可以浏览和点赞公开心愿。注册并登录后，用户可以投稿、在“我的心愿”查看自己的全部投稿、编辑或删除、标记完成，并在公开和私密之间切换。“我的心愿”支持按分类筛选和气球／列表切换。公开心愿显示在主页和已完成梦想页；私密心愿仅投稿者和管理员可读取。点赞由数据库触发器计数，重复点赞由数据库唯一键阻止。

当前 Supabase 项目已应用 `supabase/migrations/002_accounts_privacy.sql`。它增加了 `user_id` 和 `is_public`，将自定义分类限制为 1–24 字，并调整 RLS 与列权限。已完成状态需再运行一次 `supabase/migrations/003_completed_wishes.sql`，为既有数据库添加状态字段和安全列权限。新建 Supabase 项目时，可运行完整初始脚本 `supabase/schema.sql`。

匿名 Auth 仍用于浏览者点赞；提交心愿必须使用注册账户。注册邮件和重置邮件受 Supabase Auth 邮件服务的限制。要允许更多用户收取验证邮件，需在 Supabase Authentication 配置自定义 SMTP。Auth 回跳地址需包含：

```
https://xiaofenwang099-dev.github.io/Ideal-wall/
```

管理员需在 Supabase Auth 创建账号，并加入 `admin_users`：

```sql
insert into public.admin_users (user_id)
select id from auth.users where lower(email) = lower('你的管理员邮箱')
on conflict (user_id) do nothing;
```

`supabase-config.js` 仅包含浏览器可公开的 Project URL 和 Publishable/anon key。绝不能把 `service_role` 或其他 secret key 放进前端或 GitHub。

## 数据表

- `wishes`：理想正文、分类、昵称、所有者、公开状态、是否完成、点赞数和发布时间。
- `wish_likes`：每个 Supabase 用户对每条公开理想的点赞记录，`(wish_id, voter_id)` 唯一。
- `admin_users`：获准管理全站投稿的管理员用户 ID。

## 部署说明

静态页面由 GitHub Pages 发布。Supabase Free 数据库保存共享投稿与点赞。示例数据是预置展示内容；其点赞数不是实际访客点赞历史。匿名点赞建议在 Supabase Authentication → Attack Protection 中配置 CAPTCHA。

相关文档：[Supabase Auth](https://supabase.com/docs/guides/auth)、[Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security)、[SMTP 配置](https://supabase.com/docs/guides/auth/auth-smtp)。

