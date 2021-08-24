#!/bin/bash

echo "Ensure that you are in the same directory as the target file"
echo "Enter filename including extension (e.g auth.log)"
read fn

awk '/Failed/ {++failedList[$0]}
	
	END {
		
		for (attempts in failedList) {
			count++
			}
		printf("\n Number of Failed attempts: %d\n", count)
		}' $fn
		
#Following block of code to get IP addresses from attacks is taken from https://gist.github.com/c25d729784ee1c3e88be240ac2177554.git 
declare -a badstrings=("Failed password for invalid user"
                "input_userauth_request: invalid user"
                "pam_unix(sshd:auth): check pass; user unknown"
                "input_userauth_request: invalid user"
                "does not map back to the address"
                "pam_unix(sshd:auth): authentication failure"
                "input_userauth_request: invalid user"
                "reverse mapping checking getaddrinfo for"
                "input_userauth_request: invalid user"
                )
# search for each of the strings in your file (this could probably be a one liner)
for i in "${badstrings[@]}"
    do
    # look for each term and add new IPs to text file
    cat $fn | grep "$i" | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | awk '{print $0}' | sort | uniq >> "temp.txt"
    done

# grab unique ips from temp and count
# End of copied code from github

awk '{!failedIP[$0]++}
	
	END {
		for (ip in failedIP) {
			count++
			}
		printf("\n Number of IP addresses from failed attempts: %d\n", count)
		} ' temp.txt


# remove the temp file
rm "temp.txt"

		
awk '/Failed/ && !/invalid/ {!list[$9]++}
	BEGIN {print "\n Valid user(s) with failed attempt(s): "}
	END {
		for (name in list) {
			count++
				printf("\t\t\t\t%d - \"%s\"\n", count, name)
			}
		}' $fn
		
awk '/Invalid user/ {invalidUser[$0]++}
	
	END {
		for (user in invalidUser) {
			count++
			}
		printf(" Invalid user attempts: %d\n", count)
		}' $fn
		
awk '/Failed/ {print $(NF-3)}' $fn | sort | uniq -c | sort -n | tail -n 1 | awk '{print "\n IP address", $2, "attacked the most for a total of", $1, "times!"}'

ip=$(awk '/Failed/ {print $13}' $fn | sort | uniq -c | sort -n | tail -n 1 | awk '{print $2}')
echo
echo -n " "$ip " is from "
cc=$(whois $ip | awk 'tolower($1) ~/country/ {print $2}')
curl -L -s https://datahub.io/core/country-list/r/0.csv | grep $cc | awk -F "," '{print $1}'
