1. Chọn đề tài
    - Sau khi trao đổi và bàn bạc nhiều hướng, tụi em quyết định chọn đề tài Deadline Tracker App.
    - Lý do chọn: cả nhóm đều là sinh viên, ai cũng hay bị trễ deadline, bị quên bài tập, đặc biệt lúc nhiều môn dồn lại rất dễ loạn. Nên bọn em muốn làm một ứng dụng theo kiểu nhắc nhở + theo dõi tiến độ cho chính mình dùng luôn.

2. Lên ý tưởng
    - Nhóm em muốn ứng dụng có các chức năng cơ bản nhưng dễ xài nhất có thể. Ý tưởng ban đầu như sau:
        + Giao diện pastel tím nhẹ nhàng, nhìn không bị rối.
        + Trang Home sẽ hiển thị deadline hôm nay và các task tổng quát.
        + Có lịch tháng → nhấn vào ngày nào thì hiện task của ngày đó.
        + Mỗi deadline có: tên, mô tả, ngày bắt đầu – kết thúc, mức độ ưu tiên màu sắc.
        + Có thanh kéo để chỉnh phần trăm tiến độ.
        + Có nhắc trước hạn 1 ngày, 3 ngày hoặc 5 ngày.
        + Có trang cài đặt để đổi avatar, tên, mật khẩu.
    - Tụi em muốn hướng app theo kiểu: gọn – dễ nhìn – dễ thao tác, sinh viên cài vào là dùng được liền, không cần học cách sử dụng.
3. Nghiên cứu
3.1 Nghiên cứu nhu cầu
    - Nhóm có khảo sát nhỏ trong lớp: đa số bạn nói hay quên deadline, hoặc nhớ nhưng không biết còn bao nhiêu ngày đến hạn, rồi tiến độ làm tới đâu. App như Google Tasks thì khá đơn giản, không có progress %, không được tùy chỉnh nhiều.
    - Vì vậy bọn em nghĩ làm thêm thanh progress + lịch tháng sẽ trực quan hơn.

3.2 Nghiên cứu các app tương tự
    Một số app như Todoist, Google Tasks, Notion… đều mạnh nhưng hơi phức tạp, không phù hợp cho người chỉ muốn xem deadline nhanh gọn. Tụi em chọn hướng “mini” cho đơn giản mà vẫn đủ tính năng cần.
3.3 Công nghệ
    - Nhóm chọn Flutter vì:
    - Chạy được cả Android và iOS.
    - Code UI dễ.
    - Sau này dễ nâng cấp.
4. Phân tích
4.1 Phân tích chức năng
    - Ứng dụng gồm các phần:
    - Quản lý deadline: thêm, sửa, xoá.
    - Theo dõi tiến độ: cập nhật % hoàn thành.
    - Lịch tháng: xem tổng quan deadline trong tháng.
    - Nhắc nhở: đặt nhắc trước hạn theo nhiều mốc thời gian.
    - Bộ lọc và thống kê: lọc theo mức độ ưu tiên, tiến độ, trạng thái.
    - Cài đặt cá nhân: đổi thông tin, avatar, mật khẩu.

4.2 Phân tích tổng quan 
    - App làm việc với dữ liệu cá nhân nên cấu trúc đơn giản, không cần chia sẻ giữa nhiều người.
    - Deadline có thể hiển thị dạng card, màu theo mức độ ưu tiên để dễ phân biệt.
    - Sử dụng lịch tháng giúp người dùng nắm tổng quát deadline trong tuần và tháng.
    - Nhắc nhở giúp người dùng không bị quên những deadline quan trọng.
    - Ứng dụng phù hợp với phạm vi môn học, không quá nặng về thuật toán nhưng vẫn có nhiều thứ để nhóm triển khai như UI, quản lý dữ liệu, thông báo…

5. Link figma: https://www.figma.com/design/rUe85UNGB2aZ0F1IS4zryw/UITable?node-id=0-1&t=VNmEYSYH3L2gF1rz-1