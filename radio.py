#!/usr/bin/python3

import argparse
import sys
import telnetlib

def remove_last_line_from_string(s):
    return s[:s.rfind('\n')]

def send_tn_command(command, parameters=""):
    try:
      tn = telnetlib.Telnet(host="127.0.0.1", port=8500)
    except:
      sys.exit("Failed to connect to telnet server, is liquidsoap running ?")

    tn.write((command + " " + parameters + "\n").encode('ascii'))
    tn.write(b"exit\n")

    return remove_last_line_from_string(tn.read_until(b"\nEND").decode('ascii'))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("command", help="getlivesource, setlivesource <source>")
    parser.add_argument("parameters", nargs='?', default="", help="action parameters")

    args = parser.parse_args()

    if args.command == "setlivesource" and args.parameters == "":
        sys.exit("Error: you need to provide a livesource to switch to")
    else:
        print(send_tn_command(args.command, args.parameters))

