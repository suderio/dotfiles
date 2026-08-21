import pytest
from port_scanner import scan_ports
from unittest.mock import patch, MagicMock


@patch("port_scanner.socket.socket")
def test_scan_ports_open(mock_socket_class):
    # Setup mock socket
    mock_socket_instance = MagicMock()
    mock_socket_class.return_value = mock_socket_instance

    # Simulate connect_ex returning 0 (port is open)
    mock_socket_instance.connect_ex.return_value = 0

    target = "127.0.0.1"
    ports = [80, 443]

    open_ports = scan_ports(target, ports)

    assert open_ports == [80, 443]
    assert mock_socket_instance.settimeout.call_count == 2
    mock_socket_instance.settimeout.assert_called_with(1)


@patch("port_scanner.socket.socket")
def test_scan_ports_closed(mock_socket_class):
    # Setup mock socket
    mock_socket_instance = MagicMock()
    mock_socket_class.return_value = mock_socket_instance

    # Simulate connect_ex returning non-zero (port is closed)
    mock_socket_instance.connect_ex.return_value = 111

    target = "127.0.0.1"
    ports = [80, 443]

    open_ports = scan_ports(target, ports)

    assert open_ports == []
    assert mock_socket_instance.settimeout.call_count == 2
    mock_socket_instance.settimeout.assert_called_with(1)
