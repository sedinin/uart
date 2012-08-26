%%% @author Tony Rogvall <tony@rogvall.se>
%%% @copyright (C) 2012, Tony Rogvall
%%% @doc
%%%    interface to uart devices
%%% @end
%%% Created : 29 Jan 2012 by Tony Rogvall <tony@rogvall.se>

-module(uart).

-export([open/2, close/1]).
-export([send/2, send_char/2]).
-export([recv/2, recv/3]).
-export([async_recv/2, async_recv/3, async_send/2]).
-export([unrecv/2]).
-export([break/2, hangup/1, flow/2]).
-export([get_modem/1, set_modem/2, clear_modem/2]).
-export([options/0]).
-export([setopt/3, setopts/2]).
-export([getopt/2, getopts/2]).

-compile(export_all).  %% testing


-define(UART_CMD_OPEN,      1).
-define(UART_CMD_HANGUP,    2).
-define(UART_CMD_CLOSE,     4).
-define(UART_CMD_FLOW,      5).
-define(UART_CMD_BREAK,     7).
-define(UART_CMD_SETOPTS,   8).
-define(UART_CMD_GETOPTS,   9).
-define(UART_CMD_SENDCHAR,  10).
-define(UART_CMD_SEND,      11).
-define(UART_CMD_GET_MODEM, 12).
-define(UART_CMD_SET_MODEM, 13).
-define(UART_CMD_CLR_MODEM, 14).
-define(UART_CMD_UNRECV,    15).
-define(UART_CMD_RECV,      16).

%% Option bits are also used as bit numbers, so do not exceed 32.
-define(UART_OPT_DEVICE, 1).
-define(UART_OPT_IBAUD,  2).
-define(UART_OPT_OBAUD,  3).
-define(UART_OPT_CSIZE,  4).
-define(UART_OPT_BUFSZ, 5).
-define(UART_OPT_BUFTM, 6).
-define(UART_OPT_STOPB,  7).
-define(UART_OPT_PARITY, 8).
-define(UART_OPT_IFLOW, 9).
-define(UART_OPT_OFLOW, 10).
-define(UART_OPT_XOFFCHAR, 11).
-define(UART_OPT_XONCHAR,  12).
-define(UART_OPT_EOLCHAR,  13).
-define(UART_OPT_ACTIVE,   15).
-define(UART_OPT_DELAY_SEND, 16).
-define(UART_OPT_DELIVER, 17).
-define(UART_OPT_MODE, 18).
-define(UART_OPT_HEADER, 20).
-define(UART_OPT_PACKET, 21).
-define(UART_OPT_PSIZE, 22).
-define(UART_OPT_HIGH,  23).
-define(UART_OPT_LOW, 24).
-define(UART_OPT_SENDTMO, 25).  %% send timeout
-define(UART_OPT_CLOSETMO, 26).  %% send close timeout
-define(UART_OPT_BUFFER,   27).
-define(UART_OPT_EXITF,     29).

-define(UART_PB_LITTLE_ENDIAN, 16#00008000). %% UART_PB_<n> 
-define(UART_PB_BYTES_MASK,    16#00000F00). %% UART_PB_<n> 0..8 allowed
-define(UART_PB_FIXED_MASK,    16#FFFF0000). %% UART_PB_RAW
-define(UART_PB_TYPE_MASK,     16#000000FF). %% UART_PB_x

-define(UART_PB_RAW,       0).
-define(UART_PB_N,         1).
-define(UART_PB_LINE_LF,   2).

-define(UART_PASSIVE, 0).
-define(UART_ACTIVE,  1).
-define(UART_ONCE,    2).

-define(UART_PARITY_NONE, 0).
-define(UART_PARITY_ODD,  1).
-define(UART_PARITY_EVEN, 2).
-define(UART_PARITY_MARK, 3).

-define(UART_DELIVER_PORT, 0).
-define(UART_DELIVER_TERM, 1).

-define(UART_MODE_LIST,   0).
-define(UART_MODE_BINARY, 1).

-define(UART_OK,      0).
-define(UART_ERROR,   1).
-define(UART_OPTIONS, 2).

-define(UART_DTR,  16#0002).
-define(UART_RTS,  16#0004).
-define(UART_CTS,  16#0008).
-define(UART_CD,   16#0010).
-define(UART_RI,   16#0020).
-define(UART_DSR,  16#0040).
-define(UART_SW,   16#8000).

-define(bool(X), if (X) -> 1; true -> 0 end).
-define(is_uart(P),  is_port((P))).
-define(is_byte(X),  (((X) band (bnot 255)) =:= 0)).

-type uart() :: port().

-type uart_option() :: 
	device | baud | ibaud | obaud | csize | bufsz |
	buftm | stopb | parity | iflow | oflow | xonchar |
	xoffchar | eolchar | active | delay_send |
	header | packet | packet_size | deliver | mode |
	high_watermark | low_watermark | send_timeout |
	send_timeout_close | buffer | exit_on_close.

-type uart_input_pins()  ::  cts | dcd | ri | dcr.
-type uart_output_pins() ::  dtr | rts.
-type uart_modem_pins() :: uart_input_pins() | uart_output_pins().

options() ->
    [
     device,          %% string()
     baud,            %% = ibaud+obaud
     ibaud,           %% unsigned()
     obaud,           %% unsigned()
     csize,           %% 5,6,7,8
     bufsz,           %% unsigned()
     buftm,           %% timer()  [{packet,0}]
     stopb,           %% 1,2,3
     parity,          %% none,odd,even,mark
     iflow,           %% [sw,rts,dtr]
     oflow,           %% [sw,cts,dsr,dcd]
     xonchar,         %% byte()
     xoffchar,        %% byte()
     eolchar,         %% byter()
     active,          %% true,false,once
     delay_send,      %% boolean()
     header,          %% unsigned()
     packet,          %% modes()
     packet_size,     %% unsigned()
     deliver,         %% port | term
     mode,            %% list | binary
     high_watermark,
     low_watermark,
     send_timeout,
     send_timeout_close,
     buffer,
     exit_on_close
    ].

%%--------------------------------------------------------------------
%% @doc
%%   Open a serial device.
%% @end
%%--------------------------------------------------------------------
-spec open(DeviceName::iolist(), Options::[{uart_option(),term()}]) ->
		  {ok,uart()} | {error,term()}.

open(DeviceName, Opts) ->
    Path = code:priv_dir(uart),
    {Type,_} = os:type(),
    Driver = "uart_drv",
    case erl_ddll:load(Path, Driver) of
	ok ->
	    Command =
		case proplists:get_bool(ftdi, Opts) of
		    true -> Driver ++ " ftdi";
		    false -> Driver ++ " " ++ atom_to_list(Type)
		end,
	    Opts1 = proplists:delete(ftdi, Opts),
	    Uart = erlang:open_port({spawn_driver, Command}, [binary]),
	    Opts2 = [{ibaud,9600},{device,DeviceName} | Opts1],
	    case setopts(Uart, Opts2) of
		ok ->
		    {ok,Uart};
		Error ->
		    erlang:port_close(Uart),
		    Error
	    end;

	Err={error,Error} ->
	    io:format("Error: ~s\n", [erl_ddll:format_error_int(Error)]),
	    Err
    end.

%%--------------------------------------------------------------------
%% @doc
%%   Close a serial device.
%% @end
%%--------------------------------------------------------------------

-spec close(Uart::uart()) -> ok | {error,term()}.

close(Uart) when ?is_uart(Uart) ->
    erlang:port_close(Uart).

%%--------------------------------------------------------------------
%% @doc
%%   Get single option value.
%% @end
%%--------------------------------------------------------------------
-spec getopt(Uart::uart(), Option::uart_option()) ->
		    {ok,term()} | {error,term()}.
    
getopt(Uart, baud) ->
    getopt(Uart, ibaud);
getopt(Uart, Opt) ->
    case command(Uart, ?UART_CMD_GETOPTS, <<(encode_opt(Opt))>>) of
	{ok,[{_,Value}]} -> {ok,Value};
	Error -> Error
    end.

%%--------------------------------------------------------------------
%% @doc
%%   Get multiple option values.
%% @end
%%--------------------------------------------------------------------

-spec getopts(Uart::uart(), Option::[uart_option()]) ->
		     {ok,[{uart_option(),term()}]} | {error,term()}.

getopts(Uart, Opts) when ?is_uart(Uart), is_list(Opts) ->
    Opts1 = translate_getopts(Opts),
    Data = << <<(encode_opt(Opt))>> || Opt <- Opts1 >>,
    case command(Uart, ?UART_CMD_GETOPTS, Data) of
	{ok, Values} ->
	    io:format("Options returned = ~p\n", [Values]),
	    {ok, translate_getopts_reply(Opts,Values)};
	Error ->
	    Error
    end.

%%--------------------------------------------------------------------
%% @doc
%%   Set single option.
%% @end
%%--------------------------------------------------------------------
-spec setopt(Uart::uart(), Option::uart_option(), Value::term()) ->
		    ok | {error,term()}.

setopt(Uart, Opt, Value) ->
    setopts(Uart, [{Opt,Value}]).

%%--------------------------------------------------------------------
%% @doc
%%   Set multiple options.
%% @end
%%--------------------------------------------------------------------
-spec setopts(Uart::uart(), Options::[{uart_option(),term()}]) ->
		     ok | {error,term()}.

setopts(Uart, Opts) when ?is_uart(Uart), is_list(Opts) ->
    Opts1 = translate_set_opts(Opts),
    Data = << <<(encode_opt(Opt,Value))/binary>> || {Opt,Value} <- Opts1 >>,
    command(Uart, ?UART_CMD_SETOPTS, Data).

%%--------------------------------------------------------------------
%% @doc
%%   Send break for Duration number of milliseconds .
%% @end
%%--------------------------------------------------------------------
-spec break(Uart::uart(), Duration::non_neg_integer()) ->
		   ok | {error,term()}.
break(Uart,Duration) when ?is_uart(Uart),
			  is_integer(Duration), Duration > 0 ->
    command(Uart, ?UART_CMD_BREAK, <<Duration:32>>).

%%--------------------------------------------------------------------
%% @doc
%%   Hangup
%% @end
%%--------------------------------------------------------------------
-spec hangup(Uart::uart()) ->
		   ok | {error,term()}.
hangup(Uart) when ?is_uart(Uart) ->
    command(Uart, ?UART_CMD_HANGUP, []).

%%--------------------------------------------------------------------
%% @doc
%%   Manage input and output flow control 
%% @end
%%--------------------------------------------------------------------
-spec flow(Uart::uart(), Mode::(input_off|input_on|output_off|output_on)) ->
		 ok | {error,term()}.

flow(Uart, input_off) when ?is_uart(Uart) ->
    command(Uart, ?UART_CMD_FLOW, [0]);
flow(Uart, input_on) when ?is_uart(Uart) ->
    command(Uart, ?UART_CMD_FLOW, [1]);
flow(Uart, output_off) when ?is_uart(Uart) ->
    command(Uart, ?UART_CMD_FLOW, [2]);
flow(Uart, output_on) when ?is_uart(Uart) ->
    command(Uart, ?UART_CMD_FLOW, [3]).

%%--------------------------------------------------------------------
%% @doc
%%   Get modem pins status.
%% @end
%%--------------------------------------------------------------------
-spec get_modem(Uart::uart()) ->
		       {ok, [uart_modem_pins()]} |
		       {error, term()}.

get_modem(Uart) ->
    command(Uart, ?UART_CMD_GET_MODEM, []).

%%--------------------------------------------------------------------
%% @doc
%%   Set modem pins.
%% @end
%%--------------------------------------------------------------------

-spec set_modem(Uart::uart(), Flags::[uart_modem_pins()]) ->
		       ok | {error, term()}.

set_modem(Uart, Fs) when is_list(Fs) ->
    Flags = encode_flags(Fs),
    command(Uart, ?UART_CMD_SET_MODEM, <<Flags:32>>).

%%--------------------------------------------------------------------
%% @doc
%%   Clear modem pins.
%% @end
%%--------------------------------------------------------------------

-spec clear_modem(Uart::uart(), Flags::[uart_modem_pins()]) ->
			 ok | {error, term()}.
clear_modem(Uart, Fs) when ?is_uart(Uart), is_list(Fs) ->
    Flags = encode_flags(Fs),
    command(Uart, ?UART_CMD_CLR_MODEM, <<Flags:32>>).

%%--------------------------------------------------------------------
%% @doc
%%   Send characters
%% @end
%%--------------------------------------------------------------------

-spec send(Uart::uart(), Data::iolist()) ->
		  ok | {error, term()}.

send(Port, [C]) when is_port(Port), ?is_byte(C) ->
    command(Port, ?UART_CMD_SENDCHAR, [C]);
send(Port, <<C>>) when is_port(Port) ->
    command(Port, ?UART_CMD_SENDCHAR, [C]);
send(Port, Data) when is_port(Port),is_list(Data) ->
    command(Port, ?UART_CMD_SEND, Data);
send(Port, Data) when is_port(Port), is_binary(Data) ->
    command(Port, ?UART_CMD_SEND, Data).

%%--------------------------------------------------------------------
%% @doc
%%   Send a single character
%% @end
%%--------------------------------------------------------------------
-spec send_char(Uart::uart(), C::byte()) ->
		       ok | {error, term()}.

send_char(Port, C) when ?is_uart(Port), ?is_byte(C) ->
    command(Port, ?UART_CMD_SENDCHAR, [C]).

%%--------------------------------------------------------------------
%% @doc
%%   Send asynchronous data 
%% @end
%%--------------------------------------------------------------------
-spec async_send(Uart::uart(), Data::iolist()) -> ok.

async_send(Port, Data) ->
    true = erlang:port_command(Port, Data),
    ok.

%%--------------------------------------------------------------------
%% @doc
%%   Push back data onto the receice buffer
%% @end
%%--------------------------------------------------------------------
-spec unrecv(Uart::uart(), Data::iolist()) ->
		    ok | {error,term()}.

unrecv(Port, Data) when is_list(Data); is_binary(Data)  ->
    command(Port, ?UART_CMD_UNRECV, Data).

%%--------------------------------------------------------------------
%% @doc
%%   Receive data from a device in passive mode
%% @end
%%--------------------------------------------------------------------    
-spec recv(Uart::uart(), Length::non_neg_integer()) ->
		  {ok,iolist()} | {error, term()}.
    
recv(Port, Length) ->
    recv_(Port, Length, -1).

-spec recv(Uart::uart(), Length::non_neg_integer(), Timeout::timeout()) ->
		  {ok,iolist()} | {error, term()}.

recv(Uart, Length, infinity) ->
    recv_(Uart, Length, -1);

recv(Uart, Length, Timeout) when is_integer(Timeout) ->
    recv_(Uart, Length, Timeout).

recv_(Uart, Length, Timeout) when 
      ?is_uart(Uart),
      is_integer(Length), Length >= 0 ->
    case async_recv(Uart, Length, Timeout) of
	{ok, Ref} ->
	    receive
		{Ref, Result} ->
		    Result;
		{uart_async, Uart, Ref, Data} when is_list(Data) ->
		    {ok,Data};
		{uart_async, Uart, Ref, Data} when is_binary(Data) ->
		    {ok,Data};
		{uart_async, Uart, Ref, Other} ->
		    Other;
		{'EXIT', Uart, _Reason} ->
		    {error, closed}
	    end;
	Error -> Error
    end.

%%--------------------------------------------------------------------
%% @doc
%%   Initiate an async receive operation.
%% @end

-spec async_recv(Uart::uart(), Length::non_neg_integer()) ->
			{ok,integer()} | {error,term()}.

async_recv(Uart, Length) ->
    async_recv(Uart, Length, -1).

%%--------------------------------------------------------------------
%% @doc
%%   Initiate an async receive operation.
%%   To initiate an async operation reading a certain length and with
%%   a timeout the async_recv can be useful.
%%   ```{ok,Ref} = uart:async_recv(Uart, 16, 1000),
%%      receive 
%%        {uart_async,Uart,Ref,{ok,Data}} -> {ok,Data};
%%        {uart_async,Uart,Ref,{error,Reason}} -> {error,Reason};
%%        {'EXIT',Uart,_Reason} -> {error,closed}
%%        ...
%%      end'''
%%   The above can also be achived by using active once and 
%%   a fixed packet mode.
%%   ```uart:setopts(Uart, [{packet,{size,16}},{active,once}]),
%%      receive
%%         {uart,Uart,Data} -> {ok,Data};
%%         {uart_error,Uart,enxio} -> {error,usb_device_pulled_out};
%%         {uart_error,Uart,Err} -> {error,Err};
%%         {uart_closed,Uart} -> {error,close}
%%      after Timeout ->
%&         {error,timeout}
%%      end'''
%%   Packet size are however limited (to 16 bits), so any size
%%   above 64K must be handled with async_recv or split into
%%   chunks.
%% @end
%%--------------------------------------------------------------------    
    
-spec async_recv(Uart::uart(), Length::non_neg_integer(), Timeout::timeout()) ->
			{ok,integer()} | {error,term()}.

async_recv(Uart, Length, Time) ->
    command_(Uart, ?UART_CMD_RECV, [<<Time:32,Length:32>>]).


command(Uart, Cmd, Args) ->
    case command_(Uart,Cmd,Args) of
	{ok,Ref} ->
	    receive
		{Ref, Result} ->
		    Result
	    end;
	Error -> Error
    end.

command_(Uart, Cmd, Args) ->
    case erlang:port_control(Uart, Cmd, Args) of
	<<?UART_OK,Ref:32>> ->
	    {ok, Ref};
	<<?UART_ERROR>> ->
	    {error, unknown};
	<<?UART_ERROR,Reason/binary>> ->
	    {error, binary_to_atom(Reason,latin1)}
    end.

translate_set_opts([{baud,B}|Opts]) ->
    [{ibaud,B},{obaud,B}|translate_set_opts(Opts)];
translate_set_opts([Opt|Opts]) ->
    [Opt|translate_set_opts(Opts)];
translate_set_opts([]) ->
    [].

translate_getopts([baud|Opts]) ->
    [ibaud|translate_getopts(Opts)];
translate_getopts([Opt|Opts]) ->
    [Opt|translate_getopts(Opts)];
translate_getopts([]) ->
    [].

translate_getopts_reply([baud|Opts],[{ibaud,B}|Vs]) ->
    [{baud,B}|translate_getopts_reply(Opts,Vs)];
translate_getopts_reply([_Opt|Opts],[V|Vs]) ->
    [V|translate_getopts_reply(Opts,Vs)];
translate_getopts_reply([],[]) ->
    [].

%% @doc
%%    Encode UART option
%% @end
-spec encode_opt(Option::atom(),Value::term()) -> 
			ok | {ok,any()} | {error,any()}.

encode_opt(packet,0) -> 
    <<?UART_OPT_PACKET, ?UART_PB_RAW:32>>;
encode_opt(packet,PB) when PB>0, PB=< 8 -> 
    <<?UART_OPT_PACKET, (?UART_PB_N bor (PB bsl 8)):32>>;
encode_opt(packet,PB) when PB<0, PB >= -8 ->
    <<?UART_OPT_PACKET, (?UART_PB_N bor ?UART_PB_LITTLE_ENDIAN bor 
			     ((-PB) bsl 8)):32>>;
encode_opt(packet,{size,N}) when is_integer(N), N > 0, N =< 16#ffff ->
    <<?UART_OPT_PACKET, ((N bsl 16) + ?UART_PB_RAW):32>>;
encode_opt(packet,raw) ->
    <<?UART_OPT_PACKET, ?UART_PB_RAW:32>>;
encode_opt(packet,line) ->
    <<?UART_OPT_PACKET, ?UART_PB_LINE_LF:32>>;


encode_opt(device,Name) when is_list(Name); is_binary(Name) ->
    Bin = iolist_to_binary(Name),
    Len = byte_size(Bin),
    <<?UART_OPT_DEVICE,Len,Bin/binary>>;
encode_opt(ibaud,X) when X >= 0, X =< 16#ffffffff ->
    <<?UART_OPT_IBAUD,X:32>>;
encode_opt(obaud,X) when X >= 0, X =< 16#ffffffff ->
    <<?UART_OPT_OBAUD,X:32>>;
encode_opt(csize,X) when X >= 5, X =< 8 ->
    <<?UART_OPT_CSIZE,X:32>>;
encode_opt(bufsz,X) when X >= 0, X =< 16#ffffffff ->
    <<?UART_OPT_BUFSZ,X:32>>;
encode_opt(buftm,X) when X >= 0,X =< 16#ffffffff ->
    <<?UART_OPT_BUFTM,X:32>>;
encode_opt(stopb,Value) when Value >= 1, Value =< 3 ->
    <<?UART_OPT_STOPB,Value:32>>;
encode_opt(parity,none) ->
    <<?UART_OPT_PARITY,?UART_PARITY_NONE:32>>;
encode_opt(parity,odd) ->
    <<?UART_OPT_PARITY,?UART_PARITY_ODD:32>>;
encode_opt(parity,even) ->
    <<?UART_OPT_PARITY,?UART_PARITY_EVEN:32>>;
encode_opt(parity,mark) ->
    <<?UART_OPT_PARITY,?UART_PARITY_MARK:32>>;
encode_opt(oflow,Value) when is_list(Value) ->
    <<?UART_OPT_OFLOW,(encode_flags(Value)):32>>;
encode_opt(iflow,Value) when is_list(Value) ->
    <<?UART_OPT_IFLOW,(encode_flags(Value)):32>>;
encode_opt(xonchar,Value) when Value >= 0, Value =< 255 ->
    <<?UART_OPT_XONCHAR,Value:32>>;
encode_opt(xoffchar,Value) when Value >= 0, Value =< 255 ->
    <<?UART_OPT_XOFFCHAR,Value:32>>;
encode_opt(eolchar,Value) when Value >= 0, Value =< 255 ->
    <<?UART_OPT_EOLCHAR,Value:32>>;
encode_opt(active,true) ->   <<?UART_OPT_ACTIVE,?UART_ACTIVE:32>>;
encode_opt(active,false) ->   <<?UART_OPT_ACTIVE,?UART_PASSIVE:32>>;
encode_opt(active,once) ->   <<?UART_OPT_ACTIVE,?UART_ONCE:32>>;

encode_opt(delay_send,X) when is_boolean(X) ->
    <<?UART_OPT_DELAY_SEND,?bool(X):32>>;
encode_opt(header,X) when is_integer(X), X >= 0 ->
    <<?UART_OPT_HEADER, X:32>>;
encode_opt(packet_size,X) when is_integer(X), X >= 0, X =< 16#ffffffff ->
    <<?UART_OPT_PSIZE, X:32>>;    
encode_opt(deliver,port) ->
    <<?UART_OPT_DELIVER, ?UART_DELIVER_PORT:32>>;
encode_opt(deliver,term) ->
    <<?UART_OPT_DELIVER, ?UART_DELIVER_TERM:32>>;
encode_opt(mode,list) ->
    <<?UART_OPT_MODE, ?UART_MODE_LIST:32>>;
encode_opt(mode,binary) ->
    <<?UART_OPT_MODE, ?UART_MODE_BINARY:32>>;

encode_opt(packet,0) -> 
    <<?UART_OPT_PACKET, ?UART_PB_RAW:32>>;
encode_opt(packet,PB) when PB>0, PB=< 8 -> 
    <<?UART_OPT_PACKET, (?UART_PB_N bor (PB bsl 8)):32>>;
encode_opt(packet,PB) when PB<0, PB >= -8 ->
    <<?UART_OPT_PACKET, (?UART_PB_N bor ?UART_PB_LITTLE_ENDIAN bor 
			     ((-PB) bsl 8)):32>>;
encode_opt(packet,{size,N}) when is_integer(N), N > 0, N =< 16#ffff ->
    <<?UART_OPT_PACKET, ((N bsl 16) + ?UART_PB_RAW):32>>;
encode_opt(packet,raw) ->
    <<?UART_OPT_PACKET, ?UART_PB_RAW:32>>;
encode_opt(packet,line) ->
    <<?UART_OPT_PACKET, ?UART_PB_LINE_LF:32>>;
encode_opt(high_watermark,X) when is_integer(X), X >= 0, X =< 16#ffffffff ->
    <<?UART_OPT_HIGH, X:32>>;    
encode_opt(low_watermark,X) when is_integer(X), X >= 0, X =< 16#ffffffff ->
    <<?UART_OPT_LOW, X:32>>;
encode_opt(send_timeout,X) when is_integer(X),X >= -1, X =< 16#7fffffff ->
    <<?UART_OPT_SENDTMO, X:32>>;
encode_opt(send_timeout_close,X) when is_integer(X),X >= -1, X =< 16#7fffffff ->
    <<?UART_OPT_CLOSETMO, X:32>>;
encode_opt(buffer, X) when is_integer(X), X >= 0, X =< 16#ffffffff ->
    <<?UART_OPT_BUFFER, X:32>>;    
encode_opt(exit_on_close, X) when is_boolean(X) ->
    <<?UART_OPT_EXITF,?bool(X):32>>.

encode_opt(device) -> ?UART_OPT_DEVICE;
encode_opt(ibaud)  -> ?UART_OPT_IBAUD;
encode_opt(obaud)  -> ?UART_OPT_OBAUD;
encode_opt(csize)  -> ?UART_OPT_CSIZE;
encode_opt(bufsz) -> ?UART_OPT_BUFSZ;
encode_opt(buftm) -> ?UART_OPT_BUFTM;
encode_opt(stopb) -> ?UART_OPT_STOPB;
encode_opt(parity) -> ?UART_OPT_PARITY;
encode_opt(iflow) -> ?UART_OPT_IFLOW;
encode_opt(oflow) -> ?UART_OPT_OFLOW;
encode_opt(xonchar) -> ?UART_OPT_XONCHAR;
encode_opt(xoffchar) -> ?UART_OPT_XOFFCHAR;
encode_opt(eolchar) ->  ?UART_OPT_EOLCHAR;
encode_opt(active) -> ?UART_OPT_ACTIVE;
encode_opt(delay_send) -> ?UART_OPT_DELAY_SEND;
encode_opt(header)     -> ?UART_OPT_HEADER;
encode_opt(packet) ->  ?UART_OPT_PACKET;
encode_opt(packet_size) ->  ?UART_OPT_PSIZE;
encode_opt(deliver)     ->  ?UART_OPT_DELIVER;
encode_opt(mode)     ->  ?UART_OPT_MODE;
encode_opt(high_watermark) -> ?UART_OPT_HIGH;
encode_opt(low_watermark) -> ?UART_OPT_LOW;
encode_opt(send_timeout) -> ?UART_OPT_SENDTMO;
encode_opt(send_timeout_close) -> ?UART_OPT_CLOSETMO;
encode_opt(buffer) -> ?UART_OPT_BUFFER;
encode_opt(exit_on_close) -> ?UART_OPT_EXITF.
    
     
encode_flags([F|Fs]) ->
    encode_flag(F) + encode_flags(Fs);
encode_flags([]) ->
    0.

encode_flag(dtr) -> ?UART_DTR;
encode_flag(rts) -> ?UART_RTS;
encode_flag(cts) -> ?UART_CTS;
encode_flag(cd)  -> ?UART_CD;
encode_flag(ri)  -> ?UART_RI;
encode_flag(dsr) -> ?UART_DSR;
encode_flag(sw) ->  ?UART_SW.

decode_flags(Flags) when is_integer(Flags) ->
    if Flags band ?UART_DTR =/= 0 -> [dtr]; true -> [] end ++
    if Flags band ?UART_RTS =/= 0 -> [rts]; true -> [] end ++
    if Flags band ?UART_CTS =/= 0 -> [cts]; true -> [] end ++
    if Flags band ?UART_CD =/= 0  -> [cd]; true -> [] end ++
    if Flags band ?UART_RI  =/= 0 -> [ri]; true -> [] end ++
    if Flags band ?UART_DSR =/= 0 -> [dsr]; true -> [] end ++
    if Flags band ?UART_SW  =/= 0 -> [sw]; true -> [] end.
