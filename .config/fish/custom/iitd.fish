if status is-interactive
	set ip "http://10.10.78.22:3128"
	set -x http_proxy "$ip"
	set -x https_proxy "$ip"

	# conda activate ilploss
end
