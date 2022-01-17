echo "Attaching to the minecraft server."
echo "Press Ctrl+P then release P and press Q (while still holding Ctrl) to detach from the container without stopping"
echo "Press Ctrl+C to stop the container"
read -n 1 -s -r -p "Press any key to continue"
docker -H 10.10.10.67:2375 attach minecraft