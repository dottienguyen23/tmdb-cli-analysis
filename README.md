# DE Project 01 – Level 1: Phân tích dữ liệu phim TMDB bằng Linux command line

**Tác giả:** Nguyen Thi Kim Tuyen – K28

**Script hoàn chỉnh:** [`NguyenThiKimTuyen_K28_LV1_project_01.sh`](NguyenThiKimTuyen_K28_LV1_project_01.sh)

**Dữ liệu:** [tmdb-movies.csv](https://raw.githubusercontent.com/yinghaoz1/tmdb-movie-dataset-analysis/master/tmdb-movies.csv) (10.866 phim, 21 cột)

**Môi trường:** Ubuntu trên WSL

README này trình bày **quá trình** mình đi đến script cuối cùng, bao gồm các lỗi (bug) gặp phải, cách phát hiện và cách sửa. Đáp án cuối cùng nằm ở phần cuối.

---

## Mục lục

1. [Cách chạy](#1-cách-chạy)
2. [Quá trình làm và các bug gặp phải](#2-quá-trình-làm-và-các-bug-gặp-phải)
3. [Kết quả cuối cùng (Q1–Q7)](#3-kết-quả-cuối-cùng-q1q7)
4. [Q8 – Ý tưởng: phân tích chất lượng dữ liệu](#4-q8--ý-tưởng-phân-tích-chất-lượng-dữ-liệu)
5. [Hướng phát triển: tự động hoá](#5-hướng-phát-triển-tự-động-hoá)
6. [Bài học rút ra](#6-bài-học-rút-ra)

---

## 1. Cách chạy

```bash
sudo apt install miller          # công cụ đọc CSV đúng chuẩn, dùng ở bước làm sạch
bash NguyenThiKimTuyen_K28_LV1_project_01.sh
```

Script tự tải dữ liệu, nên file CSV gốc không được lưu trong repo này. Các bước bên trong script:

```
Tải dữ liệu (wget) → Làm sạch (mlr CSV → TSV) → Kiểm tra số cột → Q1–Q8
```

Ở bước kiểm tra, script in ra số cột của mỗi dòng. Kết quả đúng là `10867 21`: tất cả các dòng đều có 21 cột.

---

## 2. Quá trình làm và các bug gặp phải

### Bước 1 – Tải và khám phá dữ liệu

```bash
mkdir -p ~/tmdb && cd ~/tmdb
wget https://raw.githubusercontent.com/yinghaoz1/tmdb-movie-dataset-analysis/master/tmdb-movies.csv
ls -lh                                          # 6.6M → dữ liệu thật, không phải trang lỗi
head -1 tmdb-movies.csv | tr ',' '\n' | nl      # đánh số các cột
wc -l tmdb-movies.csv                           # 10879 dòng
```

![download](img/01_download_ls.png)
![columns](img/02_columns_nl.png)

Bảng cột dùng xuyên suốt: `4 budget · 5 revenue · 6 original_title · 7 cast · 9 director · 14 genres · 16 release_date · 17 vote_count · 18 vote_average · 19 release_year`

---

### Bug 1 – Tách cột theo dấu phẩy cho ra sai cột

**Hiện tượng.** Lần thử đầu tiên cho Q1:

```bash
sort -t',' -k16,16r tmdb-movies.csv > movies_sorted_by_date.csv
head -5 movies_sorted_by_date.csv | cut -d',' -f6,16
```

Cột 16 lẽ ra là `release_date`, nhưng lại hiện các đoạn mô tả phim, ví dụ `Capricorn One,they must battle a sinister conspiracy…`. **Không có thông báo lỗi nào, chỉ là kết quả sai.**

![wrong columns](img/03_q1_naive_wrong_columns.png)

Kiểm tra: đếm số cột trên mỗi dòng.

```bash
awk -F',' '{print NF}' tmdb-movies.csv | sort -n | uniq -c
grep 'Capricorn One' tmdb-movies.csv | awk -F',' '{print NF}'    # 25 thay vì 21
```

Chỉ 1.706 / 10.879 dòng có đúng 21 cột.

(Ảnh chụp màn hình sẽ được cập nhật sau)

Nguyên nhân:

- Các cột chữ (overview, tagline, cast, tên phim) có dấu phẩy nằm bên trong dấu nháy "...". Lệnh cut, sort và awk không hiểu dấu nháy nên tách sai cột.
- Một số overview có xuống dòng, nên một phim bị tách thành hai dòng. Vì vậy số dòng (10.879) khác số phim (10.866).

Cách sửa: dùng Miller để đọc CSV đúng chuẩn và chuyển sang TSV (tách cột bằng tab).

```bash
mlr --icsv --otsv cat tmdb-movies.csv > tmdb.tsv
awk -F'\t' '{print NF}' tmdb.tsv | sort -n | uniq -c     # 10867 21: tất cả các dòng đều có 21 cột
```

(Ảnh chụp màn hình sẽ được cập nhật sau)

Từ đây, mọi câu hỏi đều dùng file tmdb.tsv. File CSV gốc được giữ nguyên.

---

### Bug 2 – Ngày tháng bị sắp xếp như chữ (Q1)

Hiện tượng: sau khi sắp xếp, các dòng đầu là 9/9/97, 9/9/96, 9/9/94, không phải phim năm 2015.

```bash
sort -t$'\t' -k16,16r tmdb.tsv > movies_sorted_by_date.tsv
```

(Ảnh chụp màn hình sẽ được cập nhật sau)

Nguyên nhân: ngày có dạng m/d/yy. Lệnh sort so sánh từng ký tự từ trái sang, nên 9/9/97 đứng trước 12/31/15 vì 9 lớn hơn 1.

Cách sửa: tạo một khóa dạng YYYYMMDD (lấy năm từ cột release_year), sắp xếp theo khóa này rồi bỏ khóa đi. Dòng tiêu đề được ghi riêng.

```bash
head -1 tmdb.tsv > movies_sorted_by_date.tsv
tail -n +2 tmdb.tsv | awk -F'\t' '{ split($16, d, "/"); printf "%04d%02d%02d\t%s\n", $19, d[1], d[2], $0 }' | sort -t$'\t' -k1,1r | cut -f2- >> movies_sorted_by_date.tsv
```

(Ảnh chụp màn hình sẽ được cập nhật sau)

---

### Bug 3 – Revenue = 0 là dữ liệu thiếu (Q3)

Hiện tượng: 3 phim có doanh thu thấp nhất đều có revenue = 0.

```bash
awk -F'\t' '$1 == 0' revenue_sorted.tsv | wc -l     # 6016 phim
awk -F'\t' '$1 > 0'  revenue_sorted.tsv | head -5   # các giá trị thấp nhất sau khi bỏ 0
```

(Ảnh chụp màn hình sẽ được cập nhật sau)

Phát hiện: 0 nghĩa là không có ai nhập dữ liệu. Sau khi bỏ 0, giá trị thấp nhất là 2 USD (Mallrats). Thực tế phim này thu khoảng 2 triệu USD, nên nhiều khả năng đã nhập sai đơn vị.

Cách xử lý: bỏ các phim có revenue = 0 và ghi rõ giả định này trong đáp án.

---

### Bug 4 – Giá trị rỗng và nhiều tên trong một ô (Q6, Q7)

Hiện tượng: trong bảng xếp hạng đạo diễn, hạng 2 là một dòng không có tên (44 phim không có đạo diễn).

```bash
cut -f9 tmdb.tsv | tail -n +2 | sort | uniq -c | sort -nr | head -5
```

(Ảnh chụp màn hình sẽ được cập nhật sau)

Lỗi khi sửa: mình đặt grep -v '^$' ở đầu lệnh, nên kết quả không đổi và terminal bị treo. Lý do là grep không có file đầu vào nên chờ nhập từ bàn phím. Dòng rỗng chỉ xuất hiện sau khi chạy cut -f9, nên grep phải đặt sau cut.

Ngoài ra, một số phim có nhiều đạo diễn trong cùng một ô (A|B), bị đếm như một người.

Cách sửa: tách tên bằng tr, bỏ dòng rỗng, rồi mới đếm.

```bash
cut -f9 tmdb.tsv | tail -n +2 | tr '|' '\n' | grep -v '^$' | sort | uniq -c | sort -nr | head -5
```

Kết quả sau khi sửa: Woody Allen vẫn đứng đầu (46 phim, trước là 45), dòng rỗng đã biến mất, và Martin Scorsese (31) vượt lên trên Steven Spielberg (30).

(Ảnh chụp màn hình sẽ được cập nhật sau)

Cùng cách làm này dùng cho diễn viên (cột 7) và thể loại (cột 14), chỉ cần đổi số cột.

---

## 3. Kết quả cuối cùng (Q1–Q7)

Q1. Sắp xếp phim theo ngày phát hành giảm dần

- Kết quả: file output/movies_sorted_by_date.tsv
- Phim mới nhất: 31/12/2015
- Số dòng bằng file đầu vào (10.867), không mất dòng nào

Q2. Phim có đánh giá trung bình trên 7.5

- Kết quả: file output/movies_rating_above_7_5.tsv, gồm 350 phim
- Rating thấp nhất trong kết quả: 7.6

Q3. Phim có doanh thu cao nhất và thấp nhất

- Cao nhất: Avatar, 2.781.505.847 USD
- Thấp nhất: Mallrats và Shattered Glass, 2 USD
- Ghi chú: đã loại các phim có revenue = 0 (thiếu dữ liệu). Giá trị 2 USD nhiều khả năng là lỗi đơn vị.

Q4. Tổng doanh thu tất cả các phim

- 432.720.192.875 USD (khoảng 432,7 tỷ USD)
- Ghi chú: đây là giá trị danh nghĩa, chưa điều chỉnh lạm phát. Khoảng 55% phim không có revenue, nên tổng thực tế cao hơn.

Q5. Top 10 phim có lợi nhuận cao nhất

1. Avatar: 2,54 tỷ USD
2. Star Wars: The Force Awakens: 1,87 tỷ USD
3. Titanic: 1,65 tỷ USD
4. Jurassic World: 1,36 tỷ USD
5. Furious 7: 1,32 tỷ USD
6. The Avengers: 1,30 tỷ USD
7. Harry Potter and the Deathly Hallows: Part 2: 1,20 tỷ USD
8. Avengers: Age of Ultron: 1,13 tỷ USD
9. Frozen: 1,12 tỷ USD
10. The Net: 1,08 tỷ USD

Ghi chú: chỉ tính các phim có cả budget và revenue lớn hơn 0.

Q6. Đạo diễn và diễn viên có nhiều phim nhất

- Đạo diễn: Woody Allen, 46 phim
- Diễn viên: Robert De Niro, 72 phim (tiếp theo là Samuel L. Jackson, 71 phim)
- Ghi chú: phim có nhiều đạo diễn được tính cho từng người; đã loại giá trị rỗng. Cột cast chỉ liệt kê các diễn viên chính.

Q7. Số lượng phim theo thể loại

- Drama: 4761
- Comedy: 3793
- Thriller: 2908
- Action: 2385
- Romance: 1712
- Horror: 1637
- Adventure: 1471
- Crime: 1355
- Family: 1231
- Science Fiction: 1230
- Fantasy: 916
- Mystery: 810
- Animation: 699
- Documentary: 520
- Music: 408
- History: 334
- War: 270
- Foreign: 188
- TV Movie: 167
- Western: 165

Ghi chú: một phim có thể thuộc nhiều thể loại nên các số đếm chồng lên nhau. 23 phim không có thể loại.

---

## 4. Q8 – Ý tưởng: phân tích chất lượng dữ liệu

Ý tưởng này xuất phát từ các bug ở trên: trước khi phân tích thêm, cần đo xem dữ liệu đáng tin đến mức nào.
Các vấn đề tìm thấy trong lúc làm bài:

1. Dấu phẩy bên trong text có dấu nháy
   - Số lượng: 9.173 / 10.879 dòng bị tách sai khi dùng dấu phẩy
   - Phát hiện ở: Bug 1
   - Ảnh hưởng: lệch cột mà không báo lỗi

2. Xuống dòng bên trong cột overview
   - Số lượng: 10.879 dòng nhưng chỉ có 10.866 phim
   - Phát hiện ở: Bug 1
   - Ảnh hưởng: số dòng khác số phim

3. Định dạng ngày m/d/yy
   - Số lượng: tất cả các dòng
   - Phát hiện ở: Bug 2
   - Ảnh hưởng: không sắp xếp đúng được; năm 2 chữ số không rõ thế kỷ

4. Revenue = 0 (thiếu dữ liệu)
   - Số lượng: 6.016 phim
   - Phát hiện ở: Bug 3
   - Ảnh hưởng: tổng doanh thu bị thấp hơn thực tế

5. Đạo diễn hoặc thể loại bị rỗng
   - Số lượng: 44 phim không có đạo diễn, 23 phim không có thể loại
   - Phát hiện ở: Bug 4 và Q7
   - Ảnh hưởng: xuất hiện nhóm "rỗng" trong bảng xếp hạng

6. Ký tự bị lỗi (mojibake), ví dụ â€œ
   - Phát hiện ở: kết quả của Bug 1
   - Ảnh hưởng: chữ hiển thị bị hỏng

Tại sao dữ liệu này bị sai?
Có thể:

- Khi nhập tay: gõ sai đơn vị (revenue 2 USD), bỏ trống đạo diễn và thể loại.
- Khi lưu và export: giá trị trống bị ghi thành 0, ký tự bị lỗi encoding, ngày dạng m/d/yy.

Riêng lỗi lệch cột (Bug 1) là do cách đọc file, không phải do dữ liệu.

Áp dụng Lean và Kaizen để giảm lỗi

- Pareto: sửa trước lỗi nhiều nhất là revenue = 0.
- 5 Whys: revenue 2 USD → người nhập nghĩ đơn vị là triệu → form không ghi đơn vị và không kiểm tra.
- Poka-yoke: chống lỗi ngay khi nhập (ghi rõ đơn vị USD, cảnh báo giá trị bất thường, để trống thay vì nhập 0).
- Jidoka: pipeline tự dừng khi dữ liệu bị hỏng, thay vì tạo báo cáo sai.
- Kaizen (PDCA): chạy lại báo cáo chất lượng sau mỗi lần cập nhật dữ liệu để xem số lỗi có giảm không.

Các ý tưởng phân tích khác cho sau này:

- Số phim theo từng năm, để xem xu hướng của ngành phim
- Rating trung bình theo từng thể loại
- ROI (revenue / budget) theo từng thể loại
- Đi hỏi thểm người có domain trong lĩnh vực này, KPI nào quan trọng

---

## 5. Hướng phát triển: tự động hoá

- Cho script tự dừng khi dữ liệu bị hỏng, để không tạo báo cáo sai.
- Dùng cron để script tự chạy mỗi ngày, ví dụ lúc 6 giờ sáng.

---

## 6. Bài học rút ra

1. **Kiểm tra delimiter trước khi tin bất kỳ cột nào**: `awk -F',' '{print NF}' file | sort -n | uniq -c`. File sạch chỉ cho ra một dòng.
2. **Bug nguy hiểm nhất là bug im lặng.** Mọi bug trong project này đều cho ra kết quả _mà không có thông báo lỗi_.
3. **Làm sạch dữ liệu một lần (chuyển sang tmdb.tsv), giữ nguyên file gốc, kiểm tra sau mỗi bước.**
4. **Dùng đúng công cụ cho đúng định dạng**: dùng bộ đọc CSV thật cho file CSV.
5. **Ngày tháng phải ở dạng ISO (`YYYYMMDD`) mới sort đúng.** Xử lý header riêng.
6. **0 không phải lúc nào cũng là không.** Kiểm tra ý nghĩa của giá trị trước khi dùng.
7. **Pipe chạy từ trái sang phải.** Bộ lọc chỉ tác động lên dữ liệu đi đến nó.
8. **Một đáp án tốt = con số + giả định + giới hạn.**
9. **Đi thẳng vào project trước luôn**
