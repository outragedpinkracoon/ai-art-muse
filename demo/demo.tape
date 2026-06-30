# demo.tape — VHS script for the README demo GIF.
# Record with:  vhs demo/demo.tape   (run from repo root)
# Output:       docs/images/demo.gif
#
# Uses demo/fake-muse, a stub that mimics the real `muse` output instantly so
# the recording is fast and repeatable. Text-only — a tour of the command flow.
# See demo/README.md.

Output docs/images/demo.gif

Set Shell zsh
Set FontSize 15
Set Width 600
Set Height 300
Set Padding 18
Set Theme "Catppuccin Mocha"
Set TypingSpeed 55ms
Set PlaybackSpeed 1.0

# Make `muse` resolve to the demo stub for this recording only.
Hide
Type "alias muse='./demo/fake-muse'" Enter
Type "clear" Enter
Show

# 1. Generate from a prompt
Type `muse generate "a grumpy cat pirate wearing an eyepatch"`
Sleep 600ms
Enter
Sleep 3.6s

Type "clear" Enter
Sleep 400ms

# 2. Regen — same look, new subject
Type "muse regen output/output_001.png 'a wise cat wizard'"
Sleep 600ms
Enter
Sleep 3.6s

Type "clear" Enter
Sleep 400ms

# 3. Restyle — same subject, new look
Type "muse restyle output/rabbit.png --style chalk"
Sleep 600ms
Enter
Sleep 3.6s

Type "clear" Enter
Sleep 400ms

# 4. Imagine — chat to develop a prompt
Type `muse imagine "a cat pirate"`
Sleep 600ms
Enter
Sleep 8.5s

Type "clear" Enter
Sleep 400ms

# 5. Critique — AI looks at the image
Type "muse critique output/output_001.png"
Sleep 600ms
Enter
Sleep 5.3s

Sleep 1.5s
