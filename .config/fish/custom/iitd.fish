if status is-interactive
	set ip "http://proxy22.iitd.ac.in:3128"
	set -x http_proxy "$ip"
	set -x https_proxy "$ip"
	set -x HTTP_PROXY "$ip"
	set -x HTTPS_PROXY "$ip"

	set -x GRB_LICENSE_FILE "$HOME/.config/gurobi/$hostname.lic"

	set -x XLA_FLAGS --xla_gpu_force_compilation_parallelism=1
	# conda activate ilploss
end
