# shop_gucci

A new Flutter project — Gucci shopping app with AI chatbot support.

## Tính năng

- Xem sản phẩm theo danh mục, thêm vào giỏ hàng, wishlist.
- Chatbot tư vấn sản phẩm bằng AI (Groq), tự động hiển thị card sản phẩm kèm ảnh/giá khi được nhắc đến, bấm vào để xem chi tiết.

## API Key

Repo này **không** chứa API key trên GitHub — key không bao giờ được commit vào code hoặc file markdown.

### Bạn bè cần làm gì khi clone repo

1. Clone repo:
```bash
   git clone https://github.com/huy12456vn-hash/Huy_shop.git
   cd Huy_shop
```

2. Nhận API key (Groq) từ bạn qua kênh riêng tư (Zalo, Messenger, v.v.) — **không** gửi qua email công khai hoặc để trong repo. Nếu chưa có key, tạo miễn phí tại: https://console.groq.com/keys

3. Chạy app với key:
```bash
   flutter run --dart-define=GROQ_API_KEY=YOUR_KEY_HERE
```

   Hoặc build release:
```bash
   flutter build apk --dart-define=GROQ_API_KEY=YOUR_KEY_HERE
```

4. Nếu dùng VS Code, tạo file `.vscode/launch.json` (file này nên thêm vào `.gitignore`, không commit):
```json
   {
     "configurations": [
       {
         "name": "shop_gucci",
         "request": "launch",
         "type": "dart",
         "args": [
           "--dart-define=GROQ_API_KEY=YOUR_KEY_HERE"
         ]
       }
     ]
   }
```

### Lưu ý bảo mật

- **Tuyệt đối không** commit key thật vào bất kỳ file nào (code, README, launch.json, .env...).
- Thêm `.env`, `.vscode/launch.json`, hoặc file chứa key thật vào `.gitignore`.
- Nếu lỡ commit key thật lên GitHub dù chỉ 1 lần, phải **thu hồi key đó ngay** — xoá commit không đủ vì key vẫn còn trong lịch sử Git.
- Gửi key cho bạn bè qua kênh nhắn tin riêng tư, không qua Issue/PR/commit message công khai.