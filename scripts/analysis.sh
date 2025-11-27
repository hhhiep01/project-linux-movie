#!/usr/bin/env bash


BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

RAW_FILE="$BASE_DIR/data/tmdb-movie.csv"
CLEAN_FILE="$BASE_DIR/data/tmdb_clean.csv"
OUT_DIR="$BASE_DIR/output"

echo "=== START ==="

clean_data(){
    echo "==========================================================================================="
    echo "[1] Cleaning data → remove empty release_date"
    csvgrep -c 16 -r "." "$RAW_FILE" > "$CLEAN_FILE"

    echo "Cleaned file saved to:"
    echo "  $CLEAN_FILE"
}

sort_by_release_date(){
    echo "==========================================================================================="
    echo "Sắp xếp các bộ phim theo ngày phát hành giảm dần rồi lưu ra một file mới"

    mkdir -p "$OUT_DIR"
    csvsort -c release_date -r "$CLEAN_FILE" \
        > "$OUT_DIR/movies_sorted_by_date.csv"

    echo "Sorted file saved to:"
    echo "   $OUT_DIR/movies_sorted_by_date.csv"
}
filter_ranking(){
    echo "==========================================================================================="
    echo "Lọc ra các bộ phim có đánh giá trung bình trên 7.5 rồi lưu ra một file mới"
    csvsql --query "select * from tmdb_clean where vote_average > 7.5" \
           "$CLEAN_FILE" > "$OUT_DIR/high_rating.csv"
    echo "Filter file saved to:"
    echo "   $OUT_DIR/high_rating.csv"
}
highest_and_lowest_revenue(){
    echo "==========================================================================================="
    echo "Tìm ra phim nào có doanh thu cao nhất và doanh thu thấp nhất"

    echo "Phim có doanh thu cao nhất:"
    csvsql \
        --query "select original_title, director, release_date, revenue 
                 from tmdb_clean 
                 order by revenue desc 
                 limit 1" \
        "$CLEAN_FILE"

    echo ""
    echo "Phim có doanh thu thấp nhất:"
    csvsql \
        --query "select original_title, director, release_date, revenue 
                 from tmdb_clean 
                 order by revenue asc 
                 limit 1" \
        "$CLEAN_FILE"
}
total_revenue(){
    echo "==========================================================================================="
    echo "Tính tổng doanh thu tất cả các bộ phim: "
    csvsql --query "select sum(revenue)
                    from tmdb_clean" \
            "$CLEAN_FILE"      
}
top_10_profit(){
    echo "==========================================================================================="
    echo "Top 10 bộ phim đem về lợi nhuận cao nhất: "
    csvsql --query " select
                    ROW_NUMBER() OVER (order by revenue - budget desc) as rank,
                    original_title,
                    director,
                    release_date,
                    (revenue - budget) as profit
                    from tmdb_clean
                    order by profit desc
                    limit 10" \
            "$CLEAN_FILE" 
}
top_1_director_and_top_1_actor(){
    echo "==========================================================================================="
    echo "Đạo diễn nào có nhiều bộ phim nhất : "
    csvsql --query "select director, count(*) as total_movie
                    from tmdb_clean
                    group by director
                    order by total_movie desc
                    limit 1" \
            "$CLEAN_FILE" 
    echo "==========================================================================================="
    echo "Diễn viên nào đóng nhiều phim nhất: "
    csvcut -c cast "$CLEAN_FILE" \
            | tr '|' '\n' \
            | sed -e '/^$/d' -e '/^""$/d' \
            | sort \
            | uniq -c \
            | sort -nr \
            | head -1
}
genres_stats(){
    echo "==========================================================================================="
    echo "Thống kê số lượng phim theo các thể loại. Ví dụ có bao nhiêu phim thuộc thể loại Action, bao nhiêu thuộc thể loại Family, …."
     csvcut -c genres "$CLEAN_FILE" \
    | tail -n +2 \
    | tr '|' '\n' \
    | sed '/^$/d' \
    | sed '/^""$/d' \
    | sort \
    | uniq -c \
    | sort -nr
}


clean_data
sort_by_release_date
filter_ranking
highest_and_lowest_revenue
total_revenue
top_10_profit
top_1_director_and_top_1_actor
genres_stats

echo "=== DONE ==="
