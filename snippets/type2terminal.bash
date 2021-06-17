#!/usr/bin/env bash

####################################################################
# type2terminal.bash - Mac UTIL TO SUPPORT TYPING DURING SCREENCAST#
# Description:                                                     #
#   Take your clipboard content and send as keystrokes to terminal #
# invoke:                                                          #
#   /usr/local/bin/bash type2terminal.bash                         #
####################################################################


rnd ()
{
    printf "%01d\n" $[RANDOM%3+1]
}
export -f rnd

esc_semi()
{
    while read -r char_input
    do
        if [[ $char_input == ';' ]]; then
            echo "\;";
        elif [[ $char_input == '' ]]; then
            echo " ";
        else
            echo "${char_input}";
        fi
    done
}
export -f esc_semi

play ()
{
    afplay '/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/accessibility/Sticky Keys OFF.aif'
}
export -f play

export CMD_BUFFER=""

send_tmux() { 
    CLIP=$(pbpaste)

    if [ "$CLIP" = "" ]; then
        return
    fi

    echo | pbcopy
    last_index=$((${#CLIP}-1))
    last_char="${CLIP:$last_index:1}"
    first_char="${CLIP:0:1}"

    send_enter=false
    if [[ $last_char == "#" ]]; 
    then
        send_enter=true
        CLIP=${CLIP::-1}  # bash 4.2 and above
    fi

    # if the buffer is clear, then we are starting a new
    # command thus clear the screen so we get prompt in the top
    if [[ ${CMD_BUFFER} == "" ]]  && [[ $first_char != ' ' ]]; 
    then
        # echo "c" | fold -w 1 | parallel  -k 'tmux send-keys -t 0 {}; play; sleep 0.$(rnd)' # clear the screen
        tmux send-keys -t 0 "c"
        play
        tmux send-keys -t 0 Enter
        play
    fi

    echo "Processing -> ${CLIP}"
    echo $CLIP | fold -w 1 | esc_semi | parallel -k 'tmux send-keys -t 0 {}; play; sleep 0.$(rnd)'
    
    if [[ $send_enter == true ]]; then
        tmux send-keys -t 0 Enter
        export CMD_BUFFER=""
    else
        tmux send-keys -t 0 Space
        export CMD_BUFFER="${CMD_BUFFER}${CLIP}"
    fi
    play
}
export -f send_tmux

echo | pbcopy
while true
do
    send_tmux
    sleep 1
done
