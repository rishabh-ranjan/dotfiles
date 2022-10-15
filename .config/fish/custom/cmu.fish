if status is-interactive
	set ip "http://proxy.cmu.edu:3128"
	set -x http_proxy "$ip"
	set -x https_proxy "$ip"
	set -x HTTP_PROXY "$ip"
	set -x HTTPS_PROXY "$ip"
	conda activate stocl
	set -x HYDRA_FULL_ERROR "1"
end
