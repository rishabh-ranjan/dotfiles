if status is-interactive
	set ip "http://10.10.78.22:3128"
	set -x http_proxy "$ip"
	set -x https_proxy "$ip"

	set -x GRB_LICENSE_FILE "$HOME/.config/gurobi/$hostname.lic"
	conda activate ilploss
end
