import deepsecurity as api
from deepsecurity.rest import ApiException as api_exception
import codecs
import re
import time
import pickle

#DSM Host & port (must end in /api)
HOST='https://app.deepsecurity.trendmicro.com:443/api'
#API Key from the DSM
API_KEY='<You API KEY>'
# Output file
FILENAME = 'report.csv'
# API Version
api_version = 'v1'




def GetAllGroups(configuration):
    # Set search criteria
    search_criteria = api.SearchCriteria()
    search_criteria.id_value = 0
    search_criteria.id_test = "greater-than"
    # Create a search filter with maximum returned items
    page_size = 5000
    search_filter = api.SearchFilter()
    search_filter.max_items = page_size
    search_filter.search_criteria = [search_criteria]

    groupsapi = api.ComputerGroupsApi(api.ApiClient(configuration))

    paged_groups = []
    try:
        while True:
            t0 = time.time()
            groups = groupsapi.search_computer_groups(api_version, search_filter=search_filter)
            t1 = time.time()
            num_found = len(groups.computer_groups)
            if num_found == 0:
                print("No groups found.")
                break
            paged_groups.extend(groups.computer_groups)
            # Get the ID of the last group in the page and return it with the number of groups on the page
            last_id = groups.computer_groups[-1].id
            search_criteria.id_value = last_id
            print("Last ID: " + str(last_id), "Groups found: " + str(num_found))
            print ("Return rate: {0} groups/sec".format(num_found / (t1 - t0)))
            if num_found != page_size:
                print ("Num_found {0} - Page size is {1}".format(num_found, page_size))

    except api_exception as e:
        return "Exception: " + str(e)

    return paged_groups

def GetAllComputers(configuration):

    # Set search criteria
    search_criteria = api.SearchCriteria()
    search_criteria.id_value = 0
    search_criteria.id_test = "greater-than"

    # Create a search filter with maximum returned items
    page_size = 50
    search_filter = api.SearchFilter()
    search_filter.max_items = page_size
    search_filter.search_criteria = [search_criteria]

    # Perform the search and do work on the results
    computers_api = api.ComputersApi(api.ApiClient(configuration))
    paged_computers = []
    while True:
        try:
            t0 = time.time()
            computers = computers_api.search_computers(api_version, search_filter=search_filter)
            t1 = time.time()
            num_found = len(computers.computers)
            current_paged_computers = []

            if num_found == 0:
                print("No computers found.")
                break

            for computer in computers.computers:
                current_paged_computers.append(computer)

            paged_computers.append(current_paged_computers)

            # Get the ID of the last computer in the page and return it with the number of computers on the page
            last_id = computers.computers[-1].id
            search_criteria.id_value = last_id
            print("Last ID: " + str(last_id), "Computers found: " + str(num_found))
            print ("Return rate: {0} hosts/sec".format( num_found / (t1-t0) ))
            if num_found != page_size:
                print ("Num_found {0} - Page size is {1}".format(num_found, page_size))

        except api_exception as e:
            print ("Exception: {0}".format(str(e)))

    return paged_computers


def WriteToDisk(computers, groups):
        with open('computers.pkl', 'wb') as outfile:
            pickle.dump(computers, outfile)
        with open('rest_groups.pkl', 'wb') as outfile:
            pickle.dump(groups, outfile)
        return

def ReadFromDisk():
    with open('rest_groups.pkl', 'rb') as infile:
        _Groups = pickle.load(infile)
    with open('computers.pkl', 'rb') as infile:
        _RestComputers = pickle.load(infile)
    return _Groups,_RestComputers

def ConvertToHostLight( value):
    if value == "active":
        return "Managed"
    if value == "warning":
        return "Warning"
    if value == "error":
        return "Critical"
    if value == "inactive":
        return "Unmanaged"
    if value == "not-supported":
        return "Unmanaged"
    return "Unmanaged"


def _getAmazonAccount(groupid, groups, _awsAccounts, _accountPattern):
    if groupid in _awsAccounts:
        return _awsAccounts[groupid]

    for g in groups:
        if g.id == groupid:
            if g.parent_group_id != None:
                cloudAccount = _getAmazonAccount(g.parent_group_id, groups, _awsAccounts, _accountPattern)
                _awsAccounts[g.id] = cloudAccount
                return cloudAccount
            if g.id in _awsAccounts:
                return _awsAccounts[g.name]
            _awsAccounts[g.id] = g.name
            return g.name

    return '0'


def WriteCSV(pagedcomputers, groups):
    _awsAccounts = {}
    _accountPattern = re.compile("[0-9]{6,25}")

    with codecs.open(FILENAME, "w", "utf-8") as outfile:
        outfile.write(
            "AWS Instance Id,Computer Status,Status,amazon_account_id,displayName,host_name\n")
        for computers in pagedcomputers:
            for restComputer in computers:
                try:
                    account = _getAmazonAccount(restComputer.group_id,groups, _awsAccounts, _accountPattern)
                    statusMessage = "{0}".format(restComputer.computer_status.agent_status_messages)
                    statusMessage = statusMessage.replace(","," ")
                    if restComputer.ec2_virtual_machine_summary:
                        instanceid = restComputer.ec2_virtual_machine_summary.instance_id
                        if instanceid is None:
                             instanceid = "None"
                    else:
                        instanceid = "None"

                    outfile.write("{0},{1},{2},{3},{4},{5}\n".format(
                            instanceid,
                            ConvertToHostLight(restComputer.computer_status.agent_status),
                            statusMessage,
                            account,
                            restComputer.display_name,
                            restComputer.host_name
                        ))
                except Exception as err:
                    print (err)
    return


if __name__ == '__main__':
    # Add Deep Security Manager host information to the api client configuration
    configuration = api.Configuration()
    configuration.host = HOST
    configuration.verify_ssl = True
    # Authentication
    configuration.api_key['api-secret-key'] = API_KEY

    groups = GetAllGroups(configuration)
    allComputers = GetAllComputers(configuration)
    WriteToDisk(allComputers, groups)
    #groups,allComputers = ReadFromDisk()
    WriteCSV(allComputers, groups)

print "finished"
