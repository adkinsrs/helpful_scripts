#!/usr/bin/python

"""
python_template.py - Template for future python scripts
By: Shaun Adkins (sadkins@som.umarylane.edu)

"""

from argparse import ArgumentParser
import sys
import logging

########
# Main #
########

def main():
    # Set up options parser and help statement
    description = "Template file for future python scripts"
    parser = ArgumentParser(description=description)
    parser.add_argument("--input_file", "-i", help="Path to read the input file", metavar="/path/to/input.txt", required=True)
    parser.add_argument("--output_file", "-o", help="Path to write the output file", metavar="/path/to/output.txt", required=True)
    parser.add_argument("--log_file", "-l", help="Path to write the logfile", metavar="/path/to/logfile.log")
    parser.add_argument("--debug", "-d", help="Set the debug level", default="ERROR", metavar="DEBUG/INFO/WARNING/ERROR/CRITICAL")
    args = parser.parse_args()
    check_args(args, parser)

def check_args(args, parser):
    """ Validate the passed arguments """

    configure_logger(args.log_file, args.debug)

def configure_logger(filename, log_level):
    """ Creates a logger object with the appropriate level """
    num_level = getattr(logging, log_level.upper())

    # Verify that our specified log_level has a numerical value associated
    if not isinstance(num_level, int):
        raise ValueError('Invalid log level: %s' % log_level)

    # Create the logger
    logger = logging.getLogger(__name__)
    logger.setLevel(logging.DEBUG)

    # Add console handler
    ch = logging.StreamHandler()
    ch.setLevel(num_level)
    logger.addHandler(ch)

    # If a log_file argument was provided, write to that too
    if filename:
        log_fh = logging.FileHandler(filename, mode='w')
        log_fh.setLevel(logging.DEBUG)	# Let's write all output to the logfile
        formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
        log_fh.setFormatter(formatter)
        logger.addHandler(log_fh)

if __name__ == '__main__':
    main()
    sys.exit(0)
