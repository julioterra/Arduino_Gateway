module ArduinoGateway

  def address_valid?(address)
      address.is_a?(Hash) && address.include?(:ip) || address.include?(:port)
  end

end