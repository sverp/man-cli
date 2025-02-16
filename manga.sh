#!/bin/sh

$manga_link

get_images(){
    img_html=$(curl -s "$1")
    img_urls=$(echo "$img_html"| tr -d '\n' | grep -oP '<img class="reader-content"[^>]*src="\K[^"]+')
    if [ -z "$img_urls" ]; then
        echo "No images found."
        return
    fi

    i=1
    total=$(echo "$img_urls" | wc -l)
    img_url=$(echo "$img_urls" | sed -n "${i}p")
    echo "$img_url" | python display.py

    while true; do
	echo "$i/$total page"
        echo "1.Previous 2.Next 3.Search 4.Back to chapter list 5.Exit"
        read -r choice

        case "$choice" in
            1)
                if [ "$i" -gt 1 ]; then
                    i=$((i - 1))
		    clear
                    img_url=$(echo "$img_urls" | sed -n "${i}p")
                    echo "$img_url" | python display.py
                else
                    echo "Already at the first image."
                fi
                ;;
            2)
                if [ "$i" -lt "$total" ]; then
                    i=$((i + 1))
		    clear
                    img_url=$(echo "$img_urls" | sed -n "${i}p")
                    echo "$img_url" | python display.py
                else
                    echo "Already at the last image."
                fi
                ;;
            3)
                echo "Enter title: "
                read -r title
                get_manga "$title"
                return
                ;;
            4)
                get_chapter "$manga_link"
                return
                ;;
            5)
                break
                ;;
            *)
                echo "Invalid option. Please try again."
                ;;
        esac
    done
}

get_chapter(){
    chapter_html=$(curl -s "$1")
    chapter_list=$(echo "$chapter_html" | tr -d '\n' | grep -oP '<a[^>]*class="chapter-name text-nowrap"[^>]*>([^<]+)</a>')
    chapter_title=$(echo "$chapter_list" | sed -n 's/.*<a[^>]*>\(.*\)<\/a>.*/\1/p')
   
    CHOICE=$(printf "%s" "$chapter_title" | fzf)
    if [ -n "$CHOICE" ]; then
	    echo $CHOICE
	    selected_chapter=$(echo $chapter_list | sed -n 's/.*href="\([^"]*\)"[^>]*>'"$CHOICE"'<\/a>.*/\1/p')
	    get_images $selected_chapter
	else 
		echo "no selection made"
	fi
}
    
get_manga(){
    title=$(echo "$1" | sed 's/ /%20/g')
    manga_html=$(curl -s https://m.manganelo.com/search/story/${title})
    manga_list=$(echo "$manga_html" | tr -d '\n' | grep -oP '<a[^>]*class="a-h text-nowrap item-title"[^>]*>.*?</a>')
    manga_title=$(echo "$manga_list" | sed -n 's/.*title="\([^"]*\).*/\1/p')

    CHOICE=$(printf "%s\n" "$manga_title" | fzf)
    if [ -n "$CHOICE" ]; then
	manga=$(echo "$manga_list" | grep -oP '<a[^>]*class="a-h text-nowrap item-title"[^>]*title="'"$CHOICE"'"[^>]*>.*?</a>')
        manga_link=$(echo "$manga"| sed -n 's/.*href="\([^"]*\)".*/\1/p')
        get_chapter $manga_link
    else
        echo "No selection made."
    fi
}


echo "Enter Options (1,2,..)"
echo "1. Search"
echo "2. Exit"
read -r opt

case $opt in
    "1") 
        read -p "Enter title: " title
        get_manga $title  
    ;;
    "2") break;;
esac
