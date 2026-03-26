module RvlmRedmineEmailWebhook

  # A value object describing a SOCKS5 proxy to route HTTP requests through.
  class Sock5Proxy

    attr_accessor :host, :port, :username, :password

    # @param host     [String]      Proxy hostname or IP address.
    # @param port     [Integer]     Proxy port number.
    # @param username [String, nil] Optional proxy username for authentication.
    # @param password [String, nil] Optional proxy password for authentication.
    def initialize(host:, port:, username: nil, password: nil)
      raise ArgumentError, "Parameter 'host' is required" if host.nil? || host.empty?
      raise ArgumentError, "Parameter 'port' is required" if port.nil?

      @host     = host
      @port     = port
      @username = username
      @password = password
    end

    # Serialize to a plain Hash so it can be passed safely to ActiveJob.
    def to_h
      {
        'host'     => host,
        'port'     => port,
        'username' => username,
        'password' => password,
      }
    end

    def self.from_h(hash)
      return nil if hash.nil?

      new(
        host:     hash['host'],
        port:     hash['port'],
        username: hash['username'],
        password: hash['password'],
      )
    end
  end
end
