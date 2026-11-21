# SmartHomeSystem
Smart Home Device Management and AI-based IoT Security System

# Công nghệ sử dụng

====================================
1. NODE.JS BACKEND
====================================

bcrypt              # Mã hóa mật khẩu người dùng
cors                # Cho phép giao tiếp giữa các domain khác nhau
dotenv              # Quản lý biến môi trường từ file .env
express             # Xây dựng REST API và xử lý HTTP request
jsonwebtoken        # Tạo và xác thực JSON Web Token (JWT)
mariadb             # Kết nối và truy vấn cơ sở dữ liệu MariaDB
mqtt                # Giao tiếp giữa Backend và thiết bị IoT thông qua MQTT
nodemailer          # Gửi email, chẳng hạn email xác thực tài khoản
nodemon             # Tự động khởi động lại server khi mã nguồn thay đổi


====================================
2. FLUTTER MOBILE APPLICATION
====================================

cupertino_icons         # Cung cấp bộ biểu tượng giao diện phong cách iOS
http                    # Gửi HTTP request và nhận dữ liệu từ Backend API
provider                # Quản lý trạng thái (State Management) của ứng dụng
flutter_inappwebview    # Tích hợp và hiển thị nội dung WebView trong ứng dụng
video_player            # Phát video và luồng video
flutter_secure_storage  # Lưu trữ dữ liệu nhạy cảm an toàn trên thiết bị
flutter_test            # Hỗ trợ kiểm thử ứng dụng Flutter
flutter_lints           # Kiểm tra quy tắc và chất lượng mã nguồn Dart


====================================
3. DEVELOPMENT ENVIRONMENT
====================================

Node.js             # Môi trường thực thi JavaScript phía Backend
npm                 # Công cụ quản lý thư viện Node.js
Flutter SDK         # Bộ công cụ phát triển ứng dụng Flutter
Dart SDK            # Ngôn ngữ lập trình sử dụng trong Flutter
MariaDB             # Hệ quản trị cơ sở dữ liệu
MQTT Broker         # Máy chủ trung gian truyền nhận thông điệp MQTT

# Các bước chạy dự án

- Tải thư viện cần thiết trong requirement.txt
- Khởi động server:
    Mở terminal -> truy cập đường dẫn ./smart_home_server
    Chạy lệnh: npm run dev

- Khởi động app:
    mở terminal -> truy cập đường dẫn ./smart_home_app 
    Chạy lệnh: flutter run
