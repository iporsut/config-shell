-module(server).

-export([start/0, accept_client/2]).

-define(PORT, 20715).
-define(CONFIG_FILE, "command.config").

read_config() ->
    {ok, [CommandList]} = file:consult(?CONFIG_FILE),
    CommandList.


start() ->
    CommandList = read_config(),
    {ok , Listen} = gen_tcp:listen(?PORT, [
            binary,
            {reuseaddr, true},
            {active, true}
        ]),

    spawn(?MODULE, accept_client, [Listen, CommandList]).

accept_client(Listen, CommandList) ->
    {ok, Socket} = gen_tcp:accept(Listen),
    spawn(?MODULE, accept_client, [Listen, CommandList]),
    message_loop(Socket, CommandList).

message_loop(Socket, CommandList) ->
    receive
        {tcp, Socket, Message} ->
            MessageString = binary_to_list(Message),
            Command = list_to_atom(string:sub_string(MessageString, 1, length(MessageString) - 2 )),
            case lists:member(Command, CommandList) of
                true ->
                    Result = os:cmd(Command),
                    gen_tcp:send(Socket,list_to_binary(Result));
                false ->
                    gen_tcp:send(Socket, <<"Command Not Found\n">>)
            end,
            message_loop(Socket, CommandList);
        {tcp_closed, Socket} ->
            gen_tcp:close(Socket)
    end.
