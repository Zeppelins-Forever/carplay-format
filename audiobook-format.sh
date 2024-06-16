!#/bin/bash
echo
echo "Are you sure you want to turn '$1' into an MP3 audiobook? (y/N)"
echo
read -p ">>" confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1

audiobook=$(echo $1 | tr " " "-" | tr -cd '[:alnum:]._-') #replace spaces with dashes, remove any non-alphanumeric characters.

audio_no_extension=${audiobook%.*} #list the file name without the extension
extension="${audiobook##*.}" #list only the file extension.
echo $audio_no_extension
echo $extension

if [ $extension != "mp3" ]; then
    ffmpeg -hide_banner -i "$1" $audio_no_extension.mp3
    audiobook=$audio_no_extension.mp3
else
    cp "$1" $audiobook
fi

ffprobe -hide_banner -show_chapters $audiobook | grep "TAG:"
echo
echo "Use embedded chapter markers instead of splitting audio into 10 minute sections? (Y/n)"
read -p ">>" chapter_marks
if [ $chapter_marks == "N" ] || [ $chapter_marks == "n" ]; then
    ffmpeg -hide_banner -i $audiobook -map_metadata -1 -c:v copy -c:a copy $audio_no_extension-noMdata.mp3
    mkdir $audio_no_extension
    ffmpeg -hide_banner -i $audio_no_extension-noMdata.mp3 -f segment -segment_time 600 -c copy $audio_no_extension/$audio_no_extension--%03d.mp3
    rm $audio_no_extension-noMdata.mp3
else
    python3 split_ffmpeg-DEFINITIVE.py $audiobook
    cd $audio_no_extension
    for i in *.mp3; do
        ffmpeg -hide_banner -i "$i" -map_metadata -1 -c:v copy -c:a copy "temp-$i"
        rm "$i"
    done
    a=0
    for i in *.mp3; do
        new=$(printf "$audio_no_extension--%03d.mp3" "$a")
        mv -i -- "$i" "$new"
        let a=a+1
    done
fi
rm $audiobook
