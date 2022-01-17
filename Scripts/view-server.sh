echo "Resuming screen session for server."
echo "Press Ctrl+A then release A and press D (while still holding Ctrl) to detach from the session without stopping"
echo "Press Ctrl+C to stop the session and the server"
read -n 1 -s -r -p "Press any key to continue"
screen -r
