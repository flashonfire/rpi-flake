{
  config,
  _domain_base,
  _smtp_address,
  _utils,
  ...
}:
let

  secrets = _utils.setupSecrets config {
    secrets = [
      "msmtp-smtp"
    ];
  };
in
{
  imports = [
    secrets.generate
  ];

  programs.msmtp = {
    enable = true;
    accounts.default = {
      auth = true;
      host = _smtp_address;
      port = 587;
      tls = true;
      from = "server@${_domain_base}";
      user = "server@${_domain_base}";
      passwordeval = "cat ${secrets.get "msmtp-smtp"}";
    };
  };
}
