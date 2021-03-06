#!perl -T
use utf8;
use strict;
use warnings FATAL => 'all';
use Test::More;
# why can't the bloody thing do this by default?
binmode Test::More->builder->$_, ':encoding(UTF-8)'
    for qw(output failure_output todo_output);

BEGIN {
  plan skip_all => "set EXTENDED_TESTING env var to run these"
    unless $ENV{EXTENDED_TESTING};
}

use Email::Valid qw();
use XML::LibXML qw();

sub encode_tap {
    # suitable for printing into a TAP stream, i.e. change linebreaks
    my ($string) = @_;
    # unfortunately, the tr operator is too dumb to do this
    $string =~ s[\x{a}][␊]g;
    $string =~ s[\x{d}][␍]g;
    return $string;
}

my $dom = XML::LibXML->load_xml(string => do { local $/; <DATA> });
my $valid = Email::Valid->new;

for my $test_element ($dom->findnodes('//test')) {
    my %record;
    for my $key (qw(address valid warning comment source sourcelink id)) {
        my @key_node = $test_element->getChildrenByTagName($key);
        $record{$key} = $key_node[0]->textContent if @key_node;
    }

    my $comment
      = encode_tap($record{address})
      . ' is '
      . ('true' eq $record{valid} ? q() : 'in')
      . 'valid'
      . (exists $record{comment} ? " - $record{comment}" : q())
      ;

    if ('true' eq $record{valid}) {
        ok $valid->address($record{address}), $comment;
    } elsif ('false' eq $record{valid}) {
        my $details = $valid->details || 'no details';
        ok !$valid->address($record{address}), "[$details] $comment";
    } else {
        die 'cannot happen';
    }
}

done_testing;

# http://code.iamcal.com/php/rfc822/tests.php
# http://www.dominicsayers.com/isemail/
# http://www.dominicsayers.com/isemail/isemail/extras/RFC5322BNF.html
# http://code.google.com/p/isemail/source/browse/trunk/tests/tests.xml

__DATA__
<?xml version="1.0" encoding="utf-8"?>
<tests version="2.1">
    <test>
        <address>first.last@example.com</address>
        <valid>true</valid>
        <warning>false</warning>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>1</id>
    </test>
    <test>
        <address>1234567890123456789012345678901234567890123456789012345678901234@example.com</address>
        <valid>true</valid>
        <warning>false</warning>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>2</id>
    </test>
    <test>
        <address>first.last@sub.do,com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Mistyped comma instead of dot (replaces old #3 which was the same as #57)</comment>
        <source>Rob &lt;bob@bob.com&gt;</source>
        <id>3</id>
    </test>
    <test>
        <address>"first\"last"@example.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>4</id>
    </test>
    <test>
        <address>first\@last@example.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Escaping can only happen within a quoted string</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>5</id>
    </test>
    <test>
        <address>"first@last"@example.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>6</id>
    </test>
    <test>
        <address>"first\\last"@example.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>7</id>
    </test>
    <test>
        <address>x@x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x2</address>
        <valid>true</valid>
        <warning>false</warning>
        <comment>Total length reduced to 254 characters so it's still valid</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>8</id>
    </test>
    <test>
        <address>1234567890123456789012345678901234567890123456789012345678@12345678901234567890123456789012345678901234567890123456789.12345678901234567890123456789012345678901234567890123456789.123456789012345678901234567890123456789012345678901234567890123.example.com</address>
        <valid>true</valid>
        <warning>false</warning>
        <comment>Total length reduced to 254 characters so it's still valid</comment>
        <source>RFC 3696 erratum 1690</source>
        <sourcelink>http://www.rfc-editor.org/errata_search.php?rfc=3696&amp;eid=1690</sourcelink>
        <id>9</id>
    </test>
    <test>
        <address>first.last@[12.34.56.78]</address>
        <valid>true</valid>
        <warning>true</warning>
        <source>RFC 3696 erratum 1690</source>
        <sourcelink>http://www.rfc-editor.org/errata_search.php?rfc=3696&amp;eid=1690</sourcelink>
        <id>10</id>
    </test>
    <test>
        <address>first.last@[IPv6:::12.34.56.78]</address>
        <valid>true</valid>
        <warning>true</warning>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>11</id>
    </test>
    <test>
        <address>first.last@[IPv6:1111:2222:3333::4444:12.34.56.78]</address>
        <valid>true</valid>
        <warning>true</warning>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>12</id>
    </test>
    <test>
        <address>first.last@[IPv6:1111:2222:3333:4444:5555:6666:12.34.56.78]</address>
        <valid>true</valid>
        <warning>true</warning>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>13</id>
    </test>
    <test>
        <address>first.last@[IPv6:::1111:2222:3333:4444:5555:6666]</address>
        <valid>true</valid>
        <warning>true</warning>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>14</id>
    </test>
    <test>
        <address>first.last@[IPv6:1111:2222:3333::4444:5555:6666]</address>
        <valid>true</valid>
        <warning>true</warning>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>15</id>
    </test>
    <test>
        <address>first.last@[IPv6:1111:2222:3333:4444:5555:6666::]</address>
        <valid>true</valid>
        <warning>true</warning>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>16</id>
    </test>
    <test>
        <address>first.last@[IPv6:1111:2222:3333:4444:5555:6666:7777:8888]</address>
        <valid>true</valid>
        <warning>true</warning>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>17</id>
    </test>
    <test>
        <address>first.last@x23456789012345678901234567890123456789012345678901234567890123.example.com</address>
        <valid>true</valid>
        <warning>false</warning>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>18</id>
    </test>
    <test>
        <address>first.last@1xample.com</address>
        <valid>true</valid>
        <warning>false</warning>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>19</id>
    </test>
    <test>
        <address>first.last@123.example.com</address>
        <valid>true</valid>
        <warning>false</warning>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>20</id>
    </test>
    <test>
        <address>123456789012345678901234567890123456789012345678901234567890@12345678901234567890123456789012345678901234567890123456789.12345678901234567890123456789012345678901234567890123456789.12345678901234567890123456789012345678901234567890123456789.12.example.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Entire address is longer than 254 characters</comment>
        <source>RFC 3696 erratum 1690</source>
        <sourcelink>http://www.rfc-editor.org/errata_search.php?rfc=3696&amp;eid=1690</sourcelink>
        <id>21</id>
    </test>
    <test>
        <address>first.last</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>No @</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>22</id>
    </test>
    <test>
        <address>12345678901234567890123456789012345678901234567890123456789012345@example.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Local part more than 64 characters</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>23</id>
    </test>
    <test>
        <address>.first.last@example.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Local part starts with a dot</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>24</id>
    </test>
    <test>
        <address>first.last.@example.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Local part ends with a dot</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>25</id>
    </test>
    <test>
        <address>first..last@example.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Local part has consecutive dots</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>26</id>
    </test>
    <test>
        <address>"first"last"@example.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Local part contains unescaped excluded characters</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>27</id>
    </test>
    <test>
        <address>"first\last"@example.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>Any character can be escaped in a quoted string</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>28</id>
    </test>
    <test>
        <address>"""@example.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Local part contains unescaped excluded characters</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>29</id>
    </test>
    <test>
        <address>"\"@example.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Local part cannot end with a backslash</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>30</id>
    </test>
    <test>
        <address>""@example.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Local part is effectively empty</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>31</id>
    </test>
    <test>
        <address>first\\@last@example.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Local part contains unescaped excluded characters</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>32</id>
    </test>
    <test>
        <address>first.last@</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>No domain</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>33</id>
    </test>
    <test>
        <address>x@x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Domain exceeds 255 chars</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>34</id>
    </test>
    <test>
        <address>first.last@[.12.34.56.78]</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Only char that can precede IPv4 address is ':'</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>35</id>
    </test>
    <test>
        <address>first.last@[12.34.56.789]</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Can't be interpreted as IPv4 so IPv6 tag is missing</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>36</id>
    </test>
    <test>
        <address>first.last@[::12.34.56.78]</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>IPv6 tag is missing</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>37</id>
    </test>
    <test>
        <address>first.last@[IPv5:::12.34.56.78]</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>IPv6 tag is wrong</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>38</id>
    </test>
    <test>
        <address>first.last@[IPv6:1111:2222:3333::4444:5555:12.34.56.78]</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>RFC 4291 disagrees with RFC 5321 but is cited by it</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>39</id>
    </test>
    <test>
        <address>first.last@[IPv6:1111:2222:3333:4444:5555:12.34.56.78]</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Not enough IPv6 groups</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>40</id>
    </test>
    <test>
        <address>first.last@[IPv6:1111:2222:3333:4444:5555:6666:7777:12.34.56.78]</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Too many IPv6 groups (6 max)</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>41</id>
    </test>
    <test>
        <address>first.last@[IPv6:1111:2222:3333:4444:5555:6666:7777]</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Not enough IPv6 groups</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>42</id>
    </test>
    <test>
        <address>first.last@[IPv6:1111:2222:3333:4444:5555:6666:7777:8888:9999]</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Too many IPv6 groups (8 max)</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>43</id>
    </test>
    <test>
        <address>first.last@[IPv6:1111:2222::3333::4444:5555:6666]</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Too many '::' (can be none or one)</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>44</id>
    </test>
    <test>
        <address>first.last@[IPv6:1111:2222:3333::4444:5555:6666:7777]</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>RFC 4291 disagrees with RFC 5321 but is cited by it</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>45</id>
    </test>
    <test>
        <address>first.last@[IPv6:1111:2222:333x::4444:5555]</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>x is not valid in an IPv6 address</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>46</id>
    </test>
    <test>
        <address>first.last@[IPv6:1111:2222:33333::4444:5555]</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>33333 is not a valid group in an IPv6 address</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>47</id>
    </test>
    <test>
        <address>first.last@example.123</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>TLD can't be all digits</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>48</id>
    </test>
    <test>
        <address>first.last@com</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>Mail host must be second- or lower level</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>49</id>
    </test>
    <test>
        <address>first.last@-xample.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Label can't begin with a hyphen</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>50</id>
    </test>
    <test>
        <address>first.last@exampl-.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Label can't end with a hyphen</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>51</id>
    </test>
    <test>
        <address>first.last@x234567890123456789012345678901234567890123456789012345678901234.example.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Label can't be longer than 63 octets</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>52</id>
    </test>
    <test>
        <address>"Abc\@def"@example.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <source>RFC 3696 (February 2004)</source>
        <sourcelink>http://tools.ietf.org/html/rfc3696#section-3</sourcelink>
        <id>53</id>
    </test>
    <test>
        <address>"Fred\ Bloggs"@example.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <source>RFC 3696 (as amended by erratum 2005-07-09)</source>
        <sourcelink>http://www.rfc-editor.org/errata_search.php?rfc=3696&amp;eid=246</sourcelink>
        <id>54</id>
    </test>
    <test>
        <address>"Joe.\\Blow"@example.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <source>RFC 3696 (as amended by erratum 2005-07-09)</source>
        <sourcelink>http://www.rfc-editor.org/errata_search.php?rfc=3696&amp;eid=246</sourcelink>
        <id>55</id>
    </test>
    <test>
        <address>"Abc@def"@example.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <source>RFC 3696 (as amended by erratum 2005-07-09)</source>
        <sourcelink>http://www.rfc-editor.org/errata_search.php?rfc=3696&amp;eid=246</sourcelink>
        <id>56</id>
    </test>
    <test>
        <address>"Fred Bloggs"@example.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <source>RFC 3696 (February 2004)</source>
        <sourcelink>http://tools.ietf.org/html/rfc3696#section-3</sourcelink>
        <id>57</id>
    </test>
    <test>
        <address>user+mailbox@example.com</address>
        <valid>true</valid>
        <warning>false</warning>
        <source>RFC 3696 (February 2004)</source>
        <sourcelink>http://tools.ietf.org/html/rfc3696#section-3</sourcelink>
        <id>58</id>
    </test>
    <test>
        <address>customer/department=shipping@example.com</address>
        <valid>true</valid>
        <warning>false</warning>
        <source>RFC 3696 (February 2004)</source>
        <sourcelink>http://tools.ietf.org/html/rfc3696#section-3</sourcelink>
        <id>59</id>
    </test>
    <test>
        <address>$A12345@example.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <source>RFC 3696 (February 2004)</source>
        <sourcelink>http://tools.ietf.org/html/rfc3696#section-3</sourcelink>
        <id>60</id>
    </test>
    <test>
        <address>!def!xyz%abc@example.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <source>RFC 3696 (February 2004)</source>
        <sourcelink>http://tools.ietf.org/html/rfc3696#section-3</sourcelink>
        <id>61</id>
    </test>
    <test>
        <address>_somename@example.com</address>
        <valid>true</valid>
        <warning>false</warning>
        <source>RFC 3696 (February 2004)</source>
        <sourcelink>http://tools.ietf.org/html/rfc3696#section-3</sourcelink>
        <id>62</id>
    </test>
    <test>
        <address>dclo@us.ibm.com</address>
        <valid>true</valid>
        <warning>false</warning>
        <source>Doug Lovell (LinuxJournal, June 2007)</source>
        <sourcelink>http://www.linuxjournal.com/article/9585</sourcelink>
        <id>63</id>
    </test>
    <test>
        <address>abc\@def@example.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>This example from RFC 3696 was corrected in an erratum</comment>
        <source>Doug Lovell (LinuxJournal, June 2007)</source>
        <sourcelink>http://www.linuxjournal.com/article/9585</sourcelink>
        <id>64</id>
    </test>
    <test>
        <address>abc\\@example.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>This example from RFC 3696 was corrected in an erratum</comment>
        <source>Doug Lovell (LinuxJournal, June 2007)</source>
        <sourcelink>http://www.linuxjournal.com/article/9585</sourcelink>
        <id>65</id>
    </test>
    <test>
        <address>peter.piper@example.com</address>
        <valid>true</valid>
        <warning>false</warning>
        <source>Doug Lovell (LinuxJournal, June 2007)</source>
        <sourcelink>http://www.linuxjournal.com/article/9585</sourcelink>
        <id>66</id>
    </test>
    <test>
        <address>Doug\ \"Ace\"\ Lovell@example.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Escaping can only happen in a quoted string</comment>
        <source>Doug Lovell (LinuxJournal, June 2007)</source>
        <sourcelink>http://www.linuxjournal.com/article/9585</sourcelink>
        <id>67</id>
    </test>
    <test>
        <address>"Doug \"Ace\" L."@example.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <source>Doug Lovell (LinuxJournal, June 2007)</source>
        <sourcelink>http://www.linuxjournal.com/article/9585</sourcelink>
        <id>68</id>
    </test>
    <test>
        <address>abc@def@example.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Doug Lovell says this should fail</comment>
        <source>Doug Lovell (LinuxJournal, June 2007)</source>
        <sourcelink>http://www.linuxjournal.com/article/9585</sourcelink>
        <id>69</id>
    </test>
    <test>
        <address>abc\\@def@example.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Doug Lovell says this should fail</comment>
        <source>Doug Lovell (LinuxJournal, June 2007)</source>
        <sourcelink>http://www.linuxjournal.com/article/9585</sourcelink>
        <id>70</id>
    </test>
    <test>
        <address>abc\@example.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Doug Lovell says this should fail</comment>
        <source>Doug Lovell (LinuxJournal, June 2007)</source>
        <sourcelink>http://www.linuxjournal.com/article/9585</sourcelink>
        <id>71</id>
    </test>
    <test>
        <address>@example.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>No local part</comment>
        <source>Doug Lovell (LinuxJournal, June 2007)</source>
        <sourcelink>http://www.linuxjournal.com/article/9585</sourcelink>
        <id>72</id>
    </test>
    <test>
        <address>doug@</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Doug Lovell says this should fail</comment>
        <source>Doug Lovell (LinuxJournal, June 2007)</source>
        <sourcelink>http://www.linuxjournal.com/article/9585</sourcelink>
        <id>73</id>
    </test>
    <test>
        <address>"qu@example.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Doug Lovell says this should fail</comment>
        <source>Doug Lovell (LinuxJournal, June 2007)</source>
        <sourcelink>http://www.linuxjournal.com/article/9585</sourcelink>
        <id>74</id>
    </test>
    <test>
        <address>ote"@example.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Doug Lovell says this should fail</comment>
        <source>Doug Lovell (LinuxJournal, June 2007)</source>
        <sourcelink>http://www.linuxjournal.com/article/9585</sourcelink>
        <id>75</id>
    </test>
    <test>
        <address>.dot@example.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Doug Lovell says this should fail</comment>
        <source>Doug Lovell (LinuxJournal, June 2007)</source>
        <sourcelink>http://www.linuxjournal.com/article/9585</sourcelink>
        <id>76</id>
    </test>
    <test>
        <address>dot.@example.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Doug Lovell says this should fail</comment>
        <source>Doug Lovell (LinuxJournal, June 2007)</source>
        <sourcelink>http://www.linuxjournal.com/article/9585</sourcelink>
        <id>77</id>
    </test>
    <test>
        <address>two..dot@example.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Doug Lovell says this should fail</comment>
        <source>Doug Lovell (LinuxJournal, June 2007)</source>
        <sourcelink>http://www.linuxjournal.com/article/9585</sourcelink>
        <id>78</id>
    </test>
    <test>
        <address>"Doug "Ace" L."@example.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Doug Lovell says this should fail</comment>
        <source>Doug Lovell (LinuxJournal, June 2007)</source>
        <sourcelink>http://www.linuxjournal.com/article/9585</sourcelink>
        <id>79</id>
    </test>
    <test>
        <address>Doug\ \"Ace\"\ L\.@example.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Doug Lovell says this should fail</comment>
        <source>Doug Lovell (LinuxJournal, June 2007)</source>
        <sourcelink>http://www.linuxjournal.com/article/9585</sourcelink>
        <id>80</id>
    </test>
    <test>
        <address>hello world@example.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Doug Lovell says this should fail</comment>
        <source>Doug Lovell (LinuxJournal, June 2007)</source>
        <sourcelink>http://www.linuxjournal.com/article/9585</sourcelink>
        <id>81</id>
    </test>
    <test>
        <address>gatsby@f.sc.ot.t.f.i.tzg.era.l.d.</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Doug Lovell says this should fail</comment>
        <source>Doug Lovell (LinuxJournal, June 2007)</source>
        <sourcelink>http://www.linuxjournal.com/article/9585</sourcelink>
        <id>82</id>
    </test>
    <test>
        <valid>true</valid>
        <warning>false</warning>
        <address>test@example.com</address>
        <source>Dave Child</source>
        <sourcelink>http://code.google.com/p/php-email-address-validation/</sourcelink>
        <id>83</id>
    </test>
    <test>
        <valid>true</valid>
        <warning>false</warning>
        <address>TEST@example.com</address>
        <source>Dave Child</source>
        <sourcelink>http://code.google.com/p/php-email-address-validation/</sourcelink>
        <id>84</id>
    </test>
    <test>
        <valid>true</valid>
        <warning>false</warning>
        <address>1234567890@example.com</address>
        <source>Dave Child</source>
        <sourcelink>http://code.google.com/p/php-email-address-validation/</sourcelink>
        <id>85</id>
    </test>
    <test>
        <valid>true</valid>
        <warning>false</warning>
        <address>test+test@example.com</address>
        <source>Dave Child</source>
        <sourcelink>http://code.google.com/p/php-email-address-validation/</sourcelink>
        <id>86</id>
    </test>
    <test>
        <valid>true</valid>
        <warning>false</warning>
        <address>test-test@example.com</address>
        <source>Dave Child</source>
        <sourcelink>http://code.google.com/p/php-email-address-validation/</sourcelink>
        <id>87</id>
    </test>
    <test>
        <valid>true</valid>
        <warning>false</warning>
        <address>t*est@example.com</address>
        <source>Dave Child</source>
        <sourcelink>http://code.google.com/p/php-email-address-validation/</sourcelink>
        <id>88</id>
    </test>
    <test>
        <valid>true</valid>
        <warning>true</warning>
        <address>+1~1+@example.com</address>
        <source>Dave Child</source>
        <sourcelink>http://code.google.com/p/php-email-address-validation/</sourcelink>
        <id>89</id>
    </test>
    <test>
        <valid>true</valid>
        <warning>true</warning>
        <address>{_test_}@example.com</address>
        <source>Dave Child</source>
        <sourcelink>http://code.google.com/p/php-email-address-validation/</sourcelink>
        <id>90</id>
    </test>
    <test>
        <valid>true</valid>
        <warning>true</warning>
        <address>"[[ test ]]"@example.com</address>
        <source>Dave Child</source>
        <sourcelink>http://code.google.com/p/php-email-address-validation/</sourcelink>
        <id>91</id>
    </test>
    <test>
        <valid>true</valid>
        <warning>false</warning>
        <address>test.test@example.com</address>
        <source>Dave Child</source>
        <sourcelink>http://code.google.com/p/php-email-address-validation/</sourcelink>
        <id>92</id>
    </test>
    <test>
        <valid>true</valid>
        <warning>true</warning>
        <address>"test.test"@example.com</address>
        <source>Dave Child</source>
        <sourcelink>http://code.google.com/p/php-email-address-validation/</sourcelink>
        <id>93</id>
    </test>
    <test>
        <valid>true</valid>
        <warning>true</warning>
        <address>test."test"@example.com</address>
        <comment>Obsolete form, but documented in RFC 5322</comment>
        <source>Dave Child</source>
        <sourcelink>http://code.google.com/p/php-email-address-validation/</sourcelink>
        <id>94</id>
    </test>
    <test>
        <valid>true</valid>
        <warning>true</warning>
        <address>"test@test"@example.com</address>
        <source>Dave Child</source>
        <sourcelink>http://code.google.com/p/php-email-address-validation/</sourcelink>
        <id>95</id>
    </test>
    <test>
        <valid>true</valid>
        <warning>false</warning>
        <address>test@123.123.123.x123</address>
        <source>Dave Child</source>
        <sourcelink>http://code.google.com/p/php-email-address-validation/</sourcelink>
        <id>96</id>
    </test>
    <test>
        <valid>true</valid>
        <warning>true</warning>
        <address>test@123.123.123.123</address>
        <comment>Top Level Domain won't be all-numeric (see RFC 3696 Section 2). I disagree with Dave Child on this one.</comment>
        <source>Dave Child</source>
        <sourcelink>http://code.google.com/p/php-email-address-validation/</sourcelink>
        <id>97</id>
    </test>
    <test>
        <valid>true</valid>
        <warning>true</warning>
        <address>test@[123.123.123.123]</address>
        <source>Dave Child</source>
        <sourcelink>http://code.google.com/p/php-email-address-validation/</sourcelink>
        <id>98</id>
    </test>
    <test>
        <valid>true</valid>
        <warning>false</warning>
        <address>test@example.example.com</address>
        <source>Dave Child</source>
        <sourcelink>http://code.google.com/p/php-email-address-validation/</sourcelink>
        <id>99</id>
    </test>
    <test>
        <valid>true</valid>
        <warning>false</warning>
        <address>test@example.example.example.com</address>
        <source>Dave Child</source>
        <sourcelink>http://code.google.com/p/php-email-address-validation/</sourcelink>
        <id>100</id>
    </test>
    <test>
        <valid>false</valid>
        <warning>false</warning>
        <address>test.example.com</address>
        <source>Dave Child</source>
        <sourcelink>http://code.google.com/p/php-email-address-validation/</sourcelink>
        <id>101</id>
    </test>
    <test>
        <valid>false</valid>
        <warning>false</warning>
        <address>test.@example.com</address>
        <source>Dave Child</source>
        <sourcelink>http://code.google.com/p/php-email-address-validation/</sourcelink>
        <id>102</id>
    </test>
    <test>
        <valid>false</valid>
        <warning>false</warning>
        <address>test..test@example.com</address>
        <source>Dave Child</source>
        <sourcelink>http://code.google.com/p/php-email-address-validation/</sourcelink>
        <id>103</id>
    </test>
    <test>
        <valid>false</valid>
        <warning>false</warning>
        <address>.test@example.com</address>
        <source>Dave Child</source>
        <sourcelink>http://code.google.com/p/php-email-address-validation/</sourcelink>
        <id>104</id>
    </test>
    <test>
        <valid>false</valid>
        <warning>false</warning>
        <address>test@test@example.com</address>
        <source>Dave Child</source>
        <sourcelink>http://code.google.com/p/php-email-address-validation/</sourcelink>
        <id>105</id>
    </test>
    <test>
        <valid>false</valid>
        <warning>false</warning>
        <address>test@@example.com</address>
        <source>Dave Child</source>
        <sourcelink>http://code.google.com/p/php-email-address-validation/</sourcelink>
        <id>106</id>
    </test>
    <test>
        <valid>false</valid>
        <warning>false</warning>
        <address>-- test --@example.com</address>
        <comment>No spaces allowed in local part</comment>
        <source>Dave Child</source>
        <sourcelink>http://code.google.com/p/php-email-address-validation/</sourcelink>
        <id>107</id>
    </test>
    <test>
        <valid>false</valid>
        <warning>false</warning>
        <address>[test]@example.com</address>
        <comment>Square brackets only allowed within quotes</comment>
        <source>Dave Child</source>
        <sourcelink>http://code.google.com/p/php-email-address-validation/</sourcelink>
        <id>108</id>
    </test>
    <test>
        <valid>true</valid>
        <warning>true</warning>
        <address>"test\test"@example.com</address>
        <comment>Any character can be escaped in a quoted string</comment>
        <source>Dave Child</source>
        <sourcelink>http://code.google.com/p/php-email-address-validation/</sourcelink>
        <id>109</id>
    </test>
    <test>
        <valid>false</valid>
        <warning>false</warning>
        <address>"test"test"@example.com</address>
        <comment>Quotes cannot be nested</comment>
        <source>Dave Child</source>
        <sourcelink>http://code.google.com/p/php-email-address-validation/</sourcelink>
        <id>110</id>
    </test>
    <test>
        <valid>false</valid>
        <warning>false</warning>
        <address>()[]\;:,&gt;&lt;@example.com</address>
        <comment>Disallowed Characters</comment>
        <source>Dave Child</source>
        <sourcelink>http://code.google.com/p/php-email-address-validation/</sourcelink>
        <id>111</id>
    </test>
    <test>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Dave Child says so</comment>
        <address>test@.</address>
        <source>Dave Child</source>
        <sourcelink>http://code.google.com/p/php-email-address-validation/</sourcelink>
        <id>112</id>
    </test>
    <test>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Dave Child says so</comment>
        <address>test@example.</address>
        <source>Dave Child</source>
        <sourcelink>http://code.google.com/p/php-email-address-validation/</sourcelink>
        <id>113</id>
    </test>
    <test>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Dave Child says so</comment>
        <address>test@.org</address>
        <source>Dave Child</source>
        <sourcelink>http://code.google.com/p/php-email-address-validation/</sourcelink>
        <id>114</id>
    </test>
    <test>
        <valid>false</valid>
        <warning>false</warning>
        <address>test@123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012.com</address>
        <comment>255 characters is maximum length for domain. This is 256.</comment>
        <source>Dave Child</source>
        <sourcelink>http://code.google.com/p/php-email-address-validation/</sourcelink>
        <id>115</id>
    </test>
    <test>
        <valid>true</valid>
        <warning>true</warning>
        <comment>Dave Child says so</comment>
        <address>test@example</address>
        <source>Dave Child</source>
        <sourcelink>http://code.google.com/p/php-email-address-validation/</sourcelink>
        <id>116</id>
    </test>
    <test>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Dave Child says so</comment>
        <address>test@[123.123.123.123</address>
        <source>Dave Child</source>
        <sourcelink>http://code.google.com/p/php-email-address-validation/</sourcelink>
        <id>117</id>
    </test>
    <test>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Dave Child says so</comment>
        <address>test@123.123.123.123]</address>
        <source>Dave Child</source>
        <sourcelink>http://code.google.com/p/php-email-address-validation/</sourcelink>
        <id>118</id>
    </test>
    <test>
        <address>NotAnEmail</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Phil Haack says so</comment>
        <source>Phil Haack</source>
        <sourcelink>http://haacked.com/archive/2007/08/21/i-knew-how-to-validate-an-email-address-until-i.aspx</sourcelink>
        <id>119</id>
    </test>
    <test>
        <address>@NotAnEmail</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Phil Haack says so</comment>
        <source>Phil Haack</source>
        <sourcelink>http://haacked.com/archive/2007/08/21/i-knew-how-to-validate-an-email-address-until-i.aspx</sourcelink>
        <id>120</id>
    </test>
    <test>
        <address>"test\\blah"@example.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <source>Phil Haack</source>
        <sourcelink>http://haacked.com/archive/2007/08/21/i-knew-how-to-validate-an-email-address-until-i.aspx</sourcelink>
        <id>121</id>
    </test>
    <test>
        <address>"test\blah"@example.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>Any character can be escaped in a quoted string</comment>
        <source>Phil Haack</source>
        <sourcelink>http://haacked.com/archive/2007/08/21/i-knew-how-to-validate-an-email-address-until-i.aspx</sourcelink>
        <id>122</id>
    </test>
    <test>
        <address>"test\&#13;blah"@example.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>Quoted string specifically excludes carriage returns unless escaped</comment>
        <source>Phil Haack</source>
        <sourcelink>http://haacked.com/archive/2007/08/21/i-knew-how-to-validate-an-email-address-until-i.aspx</sourcelink>
        <id>123</id>
    </test>
    <test>
        <address>"test&#13;blah"@example.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Quoted string specifically excludes carriage returns</comment>
        <source>Phil Haack</source>
        <sourcelink>http://haacked.com/archive/2007/08/21/i-knew-how-to-validate-an-email-address-until-i.aspx</sourcelink>
        <id>124</id>
    </test>
    <test>
        <address>"test\"blah"@example.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <source>Phil Haack</source>
        <sourcelink>http://haacked.com/archive/2007/08/21/i-knew-how-to-validate-an-email-address-until-i.aspx</sourcelink>
        <id>125</id>
    </test>
    <test>
        <address>"test"blah"@example.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Phil Haack says so</comment>
        <source>Phil Haack</source>
        <sourcelink>http://haacked.com/archive/2007/08/21/i-knew-how-to-validate-an-email-address-until-i.aspx</sourcelink>
        <id>126</id>
    </test>
    <test>
        <address>customer/department@example.com</address>
        <valid>true</valid>
        <warning>false</warning>
        <source>Phil Haack</source>
        <sourcelink>http://haacked.com/archive/2007/08/21/i-knew-how-to-validate-an-email-address-until-i.aspx</sourcelink>
        <id>127</id>
    </test>
    <test>
        <address>_Yosemite.Sam@example.com</address>
        <valid>true</valid>
        <warning>false</warning>
        <source>Phil Haack</source>
        <sourcelink>http://haacked.com/archive/2007/08/21/i-knew-how-to-validate-an-email-address-until-i.aspx</sourcelink>
        <id>128</id>
    </test>
    <test>
        <address>~@example.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <source>Phil Haack</source>
        <sourcelink>http://haacked.com/archive/2007/08/21/i-knew-how-to-validate-an-email-address-until-i.aspx</sourcelink>
        <id>129</id>
    </test>
    <test>
        <address>.wooly@example.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Phil Haack says so</comment>
        <source>Phil Haack</source>
        <sourcelink>http://haacked.com/archive/2007/08/21/i-knew-how-to-validate-an-email-address-until-i.aspx</sourcelink>
        <id>130</id>
    </test>
    <test>
        <address>wo..oly@example.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Phil Haack says so</comment>
        <source>Phil Haack</source>
        <sourcelink>http://haacked.com/archive/2007/08/21/i-knew-how-to-validate-an-email-address-until-i.aspx</sourcelink>
        <id>131</id>
    </test>
    <test>
        <address>pootietang.@example.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Phil Haack says so</comment>
        <source>Phil Haack</source>
        <sourcelink>http://haacked.com/archive/2007/08/21/i-knew-how-to-validate-an-email-address-until-i.aspx</sourcelink>
        <id>132</id>
    </test>
    <test>
        <address>.@example.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Phil Haack says so</comment>
        <source>Phil Haack</source>
        <sourcelink>http://haacked.com/archive/2007/08/21/i-knew-how-to-validate-an-email-address-until-i.aspx</sourcelink>
        <id>133</id>
    </test>
    <test>
        <address>"Austin@Powers"@example.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <source>Phil Haack</source>
        <sourcelink>http://haacked.com/archive/2007/08/21/i-knew-how-to-validate-an-email-address-until-i.aspx</sourcelink>
        <id>134</id>
    </test>
    <test>
        <address>Ima.Fool@example.com</address>
        <valid>true</valid>
        <warning>false</warning>
        <source>Phil Haack</source>
        <sourcelink>http://haacked.com/archive/2007/08/21/i-knew-how-to-validate-an-email-address-until-i.aspx</sourcelink>
        <id>135</id>
    </test>
    <test>
        <address>"Ima.Fool"@example.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <source>Phil Haack</source>
        <sourcelink>http://haacked.com/archive/2007/08/21/i-knew-how-to-validate-an-email-address-until-i.aspx</sourcelink>
        <id>136</id>
    </test>
    <test>
        <address>"Ima Fool"@example.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <source>Phil Haack</source>
        <sourcelink>http://haacked.com/archive/2007/08/21/i-knew-how-to-validate-an-email-address-until-i.aspx</sourcelink>
        <id>137</id>
    </test>
    <test>
        <address>Ima Fool@example.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Phil Haack says so</comment>
        <source>Phil Haack</source>
        <sourcelink>http://haacked.com/archive/2007/08/21/i-knew-how-to-validate-an-email-address-until-i.aspx</sourcelink>
        <id>138</id>
    </test>
    <test>
        <address>phil.h\@\@ck@haacked.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Escaping can only happen in a quoted string</comment>
        <source>Phil Haack</source>
        <sourcelink>http://haacked.com/archive/2007/08/21/i-knew-how-to-validate-an-email-address-until-i.aspx</sourcelink>
        <id>139</id>
    </test>
    <test>
        <address>"first"."last"@example.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>140</id>
    </test>
    <test>
        <address>"first".middle."last"@example.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>141</id>
    </test>
    <test>
        <address>"first\\"last"@example.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Contains an unescaped quote</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>142</id>
    </test>
    <test>
        <address>"first".last@example.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>obs-local-part form as described in RFC 5322</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>143</id>
    </test>
    <test>
        <address>first."last"@example.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>obs-local-part form as described in RFC 5322</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>144</id>
    </test>
    <test>
        <address>"first"."middle"."last"@example.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>obs-local-part form as described in RFC 5322</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>145</id>
    </test>
    <test>
        <address>"first.middle"."last"@example.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>obs-local-part form as described in RFC 5322</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>146</id>
    </test>
    <test>
        <address>"first.middle.last"@example.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>obs-local-part form as described in RFC 5322</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>147</id>
    </test>
    <test>
        <address>"first..last"@example.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>obs-local-part form as described in RFC 5322</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>148</id>
    </test>
    <test>
        <address>foo@[\1.2.3.4]</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>RFC 5321 specifies the syntax for address-literal and does not allow escaping</comment>
        <source>Cal Henderson</source>
        <sourcelink>http://code.iamcal.com/php/rfc822/</sourcelink>
        <id>149</id>
    </test>
    <test>
        <address>"first\\\"last"@example.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>150</id>
    </test>
    <test>
        <address>first."mid\dle"."last"@example.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>Backslash can escape anything but must escape something</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>151</id>
    </test>
    <test>
        <address>Test.&#13;&#10; Folding.&#13;&#10; Whitespace@example.com</address>
        <valid>true</valid>
        <warning>false</warning>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>152</id>
    </test>
    <test>
        <address>first."".last@example.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Contains a zero-length element</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>153</id>
    </test>
    <test>
        <address>first\last@example.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Unquoted string must be an atom</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>154</id>
    </test>
    <test>
        <address>Abc\@def@example.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Was incorrectly given as a valid address in the original RFC 3696</comment>
        <source>RFC 3696 erratum 246</source>
        <sourcelink>http://www.rfc-editor.org/errata_search.php?rfc=3696&amp;eid=246</sourcelink>
        <id>155</id>
    </test>
    <test>
        <address>Fred\ Bloggs@example.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Was incorrectly given as a valid address in the original RFC 3696</comment>
        <source>RFC 3696 erratum 246</source>
        <sourcelink>http://www.rfc-editor.org/errata_search.php?rfc=3696&amp;eid=246</sourcelink>
        <id>156</id>
    </test>
    <test>
        <address>Joe.\\Blow@example.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Was incorrectly given as a valid address in the original RFC 3696</comment>
        <source>RFC 3696 erratum 246</source>
        <sourcelink>http://www.rfc-editor.org/errata_search.php?rfc=3696&amp;eid=246</sourcelink>
        <id>157</id>
    </test>
    <test>
        <address>first.last@[IPv6:1111:2222:3333:4444:5555:6666:12.34.567.89]</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>IPv4 part contains an invalid octet</comment>
        <source>Cal Henderson</source>
        <sourcelink>http://code.iamcal.com/php/rfc822/</sourcelink>
        <id>158</id>
    </test>
    <test>
        <address>"test\&#13;&#10; blah"@example.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Folding white space can't appear within a quoted pair</comment>
        <source>Cal Henderson</source>
        <sourcelink>http://code.iamcal.com/php/rfc822/</sourcelink>
        <id>159</id>
    </test>
    <test>
        <address>"test&#13;&#10; blah"@example.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>This is a valid quoted string with folding white space</comment>
        <source>Phil Haack</source>
        <sourcelink>http://haacked.com/archive/2007/08/21/i-knew-how-to-validate-an-email-address-until-i.aspx</sourcelink>
        <id>160</id>
    </test>
    <test>
        <address>{^c\@**Dog^}@cartoon.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>This is a throwaway example from Doug Lovell's article. Actually it's not a valid address.</comment>
        <source>Doug Lovell (LinuxJournal, June 2007)</source>
        <sourcelink>http://www.linuxjournal.com/article/9585</sourcelink>
        <id>161</id>
    </test>
    <test>
        <address>(foo)cal(bar)@(baz)iamcal.com(quux)</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>A valid address containing comments</comment>
        <source>Cal Henderson</source>
        <sourcelink>http://code.iamcal.com/php/rfc822/</sourcelink>
        <id>162</id>
    </test>
    <test>
        <address>cal@iamcal(woo).(yay)com</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>A valid address containing comments</comment>
        <source>Cal Henderson</source>
        <sourcelink>http://code.iamcal.com/php/rfc822/</sourcelink>
        <id>163</id>
    </test>
    <test>
        <address>"foo"(yay)@(hoopla)[1.2.3.4]</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Address literal can't be commented (RFC 5321)</comment>
        <source>Cal Henderson</source>
        <sourcelink>http://code.iamcal.com/php/rfc822/</sourcelink>
        <id>164</id>
    </test>
    <test>
        <address>cal(woo(yay)hoopla)@iamcal.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>A valid address containing comments</comment>
        <source>Cal Henderson</source>
        <sourcelink>http://code.iamcal.com/php/rfc822/</sourcelink>
        <id>165</id>
    </test>
    <test>
        <address>cal(foo\@bar)@iamcal.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>A valid address containing comments</comment>
        <source>Cal Henderson</source>
        <sourcelink>http://code.iamcal.com/php/rfc822/</sourcelink>
        <id>166</id>
    </test>
    <test>
        <address>cal(foo\)bar)@iamcal.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>A valid address containing comments and an escaped parenthesis</comment>
        <source>Cal Henderson</source>
        <sourcelink>http://code.iamcal.com/php/rfc822/</sourcelink>
        <id>167</id>
    </test>
    <test>
        <address>cal(foo(bar)@iamcal.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Unclosed parenthesis in comment</comment>
        <source>Cal Henderson</source>
        <sourcelink>http://code.iamcal.com/php/rfc822/</sourcelink>
        <id>168</id>
    </test>
    <test>
        <address>cal(foo)bar)@iamcal.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Too many closing parentheses</comment>
        <source>Cal Henderson</source>
        <sourcelink>http://code.iamcal.com/php/rfc822/</sourcelink>
        <id>169</id>
    </test>
    <test>
        <address>cal(foo\)@iamcal.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Backslash at end of comment has nothing to escape</comment>
        <source>Cal Henderson</source>
        <sourcelink>http://code.iamcal.com/php/rfc822/</sourcelink>
        <id>170</id>
    </test>
    <test>
        <address>first().last@example.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>A valid address containing an empty comment</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>171</id>
    </test>
    <test>
        <address>first.(&#13;&#10; middle&#13;&#10; )last@example.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>Comment with folding white space</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>172</id>
    </test>
    <test>
        <address>first(12345678901234567890123456789012345678901234567890)last@(1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890)example.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Too long with comments, not too long without</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>173</id>
    </test>
    <test>
        <address>first(Welcome to&#13;&#10; the ("wonderful" (!)) world&#13;&#10; of email)@example.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>Silly example from my blog post</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>174</id>
    </test>
    <test>
        <address>pete(his account)@silly.test(his host)</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>Canonical example from RFC 5322</comment>
        <source>RFC 5322</source>
        <sourcelink>http://tools.ietf.org/html/rfc5322</sourcelink>
        <id>175</id>
    </test>
    <test>
        <address>c@(Chris's host.)public.example</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>Canonical example from RFC 5322</comment>
        <source>RFC 5322</source>
        <sourcelink>http://tools.ietf.org/html/rfc5322</sourcelink>
        <id>176</id>
    </test>
    <test>
        <address>jdoe@machine(comment).  example</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>Canonical example from RFC 5322</comment>
        <source>RFC 5322</source>
        <sourcelink>http://tools.ietf.org/html/rfc5322</sourcelink>
        <id>177</id>
    </test>
    <test>
        <address>1234   @   local(blah)  .machine .example</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>Canonical example from RFC 5322</comment>
        <source>RFC 5322</source>
        <sourcelink>http://tools.ietf.org/html/rfc5322</sourcelink>
        <id>178</id>
    </test>
    <test>
        <address>first(middle)last@example.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Can't have a comment or white space except at an element boundary</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>179</id>
    </test>
    <test>
        <address>first(abc.def).last@example.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>Comment can contain a dot</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>180</id>
    </test>
    <test>
        <address>first(a"bc.def).last@example.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>Comment can contain double quote</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>181</id>
    </test>
    <test>
        <address>first.(")middle.last(")@example.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>Comment can contain a quote</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>182</id>
    </test>
    <test>
        <address>first(abc("def".ghi).mno)middle(abc("def".ghi).mno).last@(abc("def".ghi).mno)example(abc("def".ghi).mno).(abc("def".ghi).mno)com(abc("def".ghi).mno)</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Can't have comments or white space except at an element boundary</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>183</id>
    </test>
    <test>
        <address>first(abc\(def)@example.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>Comment can contain quoted-pair</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>184</id>
    </test>
    <test>
        <address>first.last@x(1234567890123456789012345678901234567890123456789012345678901234567890).com</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>Label is longer than 63 octets, but not with comment removed</comment>
        <source>Cal Henderson</source>
        <sourcelink>http://code.iamcal.com/php/rfc822/</sourcelink>
        <id>185</id>
    </test>
    <test>
        <address>a(a(b(c)d(e(f))g)h(i)j)@example.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <source>Cal Henderson</source>
        <sourcelink>http://code.iamcal.com/php/rfc822/</sourcelink>
        <id>186</id>
    </test>
    <test>
        <address>a(a(b(c)d(e(f))g)(h(i)j)@example.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>Braces are not properly matched</comment>
        <source>Cal Henderson</source>
        <sourcelink>http://code.iamcal.com/php/rfc822/</sourcelink>
        <id>187</id>
    </test>
    <test>
        <address>name.lastname@domain.com</address>
        <valid>true</valid>
        <warning>false</warning>
        <source>Paul Gregg</source>
        <sourcelink>http://pgregg.com/projects/php/code/showvalidemail.php</sourcelink>
        <id>188</id>
    </test>
    <test>
        <address>.@</address>
        <valid>false</valid>
        <warning>false</warning>
        <source>Paul Gregg</source>
        <sourcelink>http://pgregg.com/projects/php/code/showvalidemail.php</sourcelink>
        <id>189</id>
    </test>
    <test>
        <address>a@b</address>
        <valid>true</valid>
        <warning>true</warning>
        <source>Paul Gregg</source>
        <sourcelink>http://pgregg.com/projects/php/code/showvalidemail.php</sourcelink>
        <id>190</id>
    </test>
    <test>
        <address>@bar.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <source>Paul Gregg</source>
        <sourcelink>http://pgregg.com/projects/php/code/showvalidemail.php</sourcelink>
        <id>191</id>
    </test>
    <test>
        <address>@@bar.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <source>Paul Gregg</source>
        <sourcelink>http://pgregg.com/projects/php/code/showvalidemail.php</sourcelink>
        <id>192</id>
    </test>
    <test>
        <address>a@bar.com</address>
        <valid>true</valid>
        <warning>false</warning>
        <source>Paul Gregg</source>
        <sourcelink>http://pgregg.com/projects/php/code/showvalidemail.php</sourcelink>
        <id>193</id>
    </test>
    <test>
        <address>aaa.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <source>Paul Gregg</source>
        <sourcelink>http://pgregg.com/projects/php/code/showvalidemail.php</sourcelink>
        <id>194</id>
    </test>
    <test>
        <address>aaa@.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <source>Paul Gregg</source>
        <sourcelink>http://pgregg.com/projects/php/code/showvalidemail.php</sourcelink>
        <id>195</id>
    </test>
    <test>
        <address>aaa@.123</address>
        <valid>false</valid>
        <warning>false</warning>
        <source>Paul Gregg</source>
        <sourcelink>http://pgregg.com/projects/php/code/showvalidemail.php</sourcelink>
        <id>196</id>
    </test>
    <test>
        <address>aaa@[123.123.123.123]</address>
        <valid>true</valid>
        <warning>true</warning>
        <source>Paul Gregg</source>
        <sourcelink>http://pgregg.com/projects/php/code/showvalidemail.php</sourcelink>
        <id>197</id>
    </test>
    <test>
        <address>aaa@[123.123.123.123]a</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>extra data outside ip</comment>
        <source>Paul Gregg</source>
        <sourcelink>http://pgregg.com/projects/php/code/showvalidemail.php</sourcelink>
        <id>198</id>
    </test>
    <test>
        <address>aaa@[123.123.123.333]</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>not a valid IP</comment>
        <source>Paul Gregg</source>
        <sourcelink>http://pgregg.com/projects/php/code/showvalidemail.php</sourcelink>
        <id>199</id>
    </test>
    <test>
        <address>a@bar.com.</address>
        <valid>false</valid>
        <warning>false</warning>
        <source>Paul Gregg</source>
        <sourcelink>http://pgregg.com/projects/php/code/showvalidemail.php</sourcelink>
        <id>200</id>
    </test>
    <test>
        <address>a@bar</address>
        <valid>true</valid>
        <warning>true</warning>
        <source>Paul Gregg</source>
        <sourcelink>http://pgregg.com/projects/php/code/showvalidemail.php</sourcelink>
        <id>201</id>
    </test>
    <test>
        <address>a-b@bar.com</address>
        <valid>true</valid>
        <warning>false</warning>
        <source>Paul Gregg</source>
        <sourcelink>http://pgregg.com/projects/php/code/showvalidemail.php</sourcelink>
        <id>202</id>
    </test>
    <test>
        <address>+@b.c</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>TLDs can be any length</comment>
        <source>Paul Gregg</source>
        <sourcelink>http://pgregg.com/projects/php/code/showvalidemail.php</sourcelink>
        <id>203</id>
    </test>
    <test>
        <address>+@b.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <source>Paul Gregg</source>
        <sourcelink>http://pgregg.com/projects/php/code/showvalidemail.php</sourcelink>
        <id>204</id>
    </test>
    <test>
        <address>a@-b.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <source>Paul Gregg</source>
        <sourcelink>http://pgregg.com/projects/php/code/showvalidemail.php</sourcelink>
        <id>205</id>
    </test>
    <test>
        <address>a@b-.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <source>Paul Gregg</source>
        <sourcelink>http://pgregg.com/projects/php/code/showvalidemail.php</sourcelink>
        <id>206</id>
    </test>
    <test>
        <address>-@..com</address>
        <valid>false</valid>
        <warning>false</warning>
        <source>Paul Gregg</source>
        <sourcelink>http://pgregg.com/projects/php/code/showvalidemail.php</sourcelink>
        <id>207</id>
    </test>
    <test>
        <address>-@a..com</address>
        <valid>false</valid>
        <warning>false</warning>
        <source>Paul Gregg</source>
        <sourcelink>http://pgregg.com/projects/php/code/showvalidemail.php</sourcelink>
        <id>208</id>
    </test>
    <test>
        <address>a@b.co-foo.uk</address>
        <valid>true</valid>
        <warning>false</warning>
        <source>Paul Gregg</source>
        <sourcelink>http://pgregg.com/projects/php/code/showvalidemail.php</sourcelink>
        <id>209</id>
    </test>
    <test>
        <address>"hello my name is"@stutter.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <source>Paul Gregg</source>
        <sourcelink>http://pgregg.com/projects/php/code/showvalidemail.php</sourcelink>
        <id>210</id>
    </test>
    <test>
        <address>"Test \"Fail\" Ing"@example.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <source>Paul Gregg</source>
        <sourcelink>http://pgregg.com/projects/php/code/showvalidemail.php</sourcelink>
        <id>211</id>
    </test>
    <test>
        <address>valid@special.museum</address>
        <valid>true</valid>
        <warning>false</warning>
        <source>Paul Gregg</source>
        <sourcelink>http://pgregg.com/projects/php/code/showvalidemail.php</sourcelink>
        <id>212</id>
    </test>
    <test>
        <address>invalid@special.museum-</address>
        <valid>false</valid>
        <warning>false</warning>
        <source>Paul Gregg</source>
        <sourcelink>http://pgregg.com/projects/php/code/showvalidemail.php</sourcelink>
        <id>213</id>
    </test>
    <test>
        <address>shaitan@my-domain.thisisminekthx</address>
        <valid>true</valid>
        <warning>false</warning>
        <comment>Disagree with Paul Gregg here</comment>
        <source>Paul Gregg</source>
        <sourcelink>http://pgregg.com/projects/php/code/showvalidemail.php</sourcelink>
        <id>214</id>
    </test>
    <test>
        <address>test@...........com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>......</comment>
        <source>Paul Gregg</source>
        <sourcelink>http://pgregg.com/projects/php/code/showvalidemail.php</sourcelink>
        <id>215</id>
    </test>
    <test>
        <address>foobar@192.168.0.1</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>ip need to be []</comment>
        <source>Paul Gregg</source>
        <sourcelink>http://pgregg.com/projects/php/code/showvalidemail.php</sourcelink>
        <id>216</id>
    </test>
    <test>
        <address>"Joe\\Blow"@example.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <source>Paul Gregg</source>
        <sourcelink>http://pgregg.com/projects/php/code/showvalidemail.php</sourcelink>
        <id>217</id>
    </test>
    <test>
        <address>Invalid \&#10; Folding \&#10; Whitespace@example.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <source>Paul Gregg</source>
        <comment>This isn't FWS so Dominic Sayers says it's invalid</comment>
        <sourcelink>http://pgregg.com/projects/php/code/showvalidemail.php</sourcelink>
        <id>218</id>
    </test>
    <test>
        <address>HM2Kinsists@(that comments are allowed)this.is.ok</address>
        <valid>true</valid>
        <warning>true</warning>
        <source>Paul Gregg</source>
        <sourcelink>http://pgregg.com/projects/php/code/showvalidemail.php</sourcelink>
        <id>219</id>
    </test>
    <test>
        <address>user%uucp!path@somehost.edu</address>
        <valid>true</valid>
        <warning>false</warning>
        <source>Paul Gregg</source>
        <sourcelink>http://pgregg.com/projects/php/code/showvalidemail.php</sourcelink>
        <id>220</id>
    </test>
    <test>
        <address>"first(last)"@example.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>221</id>
    </test>
    <test>
        <address> &#13;&#10; (&#13;&#10; x &#13;&#10; ) &#13;&#10; first&#13;&#10; ( &#13;&#10; x&#13;&#10; ) &#13;&#10; .&#13;&#10; ( &#13;&#10; x) &#13;&#10; last &#13;&#10; (  x &#13;&#10; ) &#13;&#10; @example.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>222</id>
    </test>
    <test>
        <address>test. &#13;&#10; &#13;&#10; obs@syntax.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>obs-fws allows multiple lines</comment>
        <source>George Pollard</source>
        <sourcelink>http://porg.es/blog/properly-validating-e-mail-addresses</sourcelink>
        <id>223</id>
    </test>
    <test>
        <address>test. &#13;&#10; &#13;&#10; obs@syntax.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>obs-fws allows multiple lines (test 2: space before break)</comment>
        <source>George Pollard</source>
        <sourcelink>http://porg.es/blog/properly-validating-e-mail-addresses</sourcelink>
        <id>224</id>
    </test>
    <test>
        <address>test.&#13;&#10;&#13;&#10; obs@syntax.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>obs-fws must have at least one WSP per line</comment>
        <source>George Pollard</source>
        <sourcelink>http://porg.es/blog/properly-validating-e-mail-addresses</sourcelink>
        <id>225</id>
    </test>
    <test>
        <address>"null \\0"@char.com</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>can have escaped null character</comment>
        <source>George Pollard</source>
        <sourcelink>http://porg.es/blog/properly-validating-e-mail-addresses</sourcelink>
        <id>226</id>
    </test>
    <test>
        <address>"null \0"@char.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>cannot have unescaped null character</comment>
        <source>George Pollard</source>
        <sourcelink>http://porg.es/blog/properly-validating-e-mail-addresses</sourcelink>
        <id>227</id>
    </test>
    <test>
        <address>null\\0@char.com</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>escaped null must be in quoted string</comment>
        <source>George Pollard</source>
        <sourcelink>http://porg.es/blog/properly-validating-e-mail-addresses</sourcelink>
        <id>228</id>
    </test>
    <test>
        <address>cdburgess+!#$%&amp;'*-/=?+_{}|~test@gmail.com</address>
        <valid>true</valid>
        <warning>false</warning>
        <comment>Example given in comments</comment>
        <source>cdburgess</source>
        <sourcelink>http://www.dominicsayers.com/isemail/#comment-30024957</sourcelink>
        <id>229</id>
    </test>
    <test>
        <address>first.last@[IPv6:::a2:a3:a4:b1:b2:b3:b4]</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>:: only elides one zero group (IPv6 authority is RFC 4291)</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>230</id>
    </test>
    <test>
        <address>first.last@[IPv6:a1:a2:a3:a4:b1:b2:b3::]</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>:: only elides one zero group (IPv6 authority is RFC 4291)</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>231</id>
    </test>
    <test>
        <address>first.last@[IPv6::]</address>
        <valid>false</valid>
        <warning>false</warning>
        <comment>IPv6 authority is RFC 4291</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>232</id>
    </test>
    <test>
        <address>first.last@[IPv6:::]</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>IPv6 authority is RFC 4291</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>233</id>
    </test>
    <test>
        <address>first.last@[IPv6::::]</address>
        <valid>false</valid>
        <warning>true</warning>
        <comment>IPv6 authority is RFC 4291</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>234</id>
    </test>
    <test>
        <address>first.last@[IPv6::b4]</address>
        <valid>false</valid>
        <warning>true</warning>
        <comment>IPv6 authority is RFC 4291</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>235</id>
    </test>
    <test>
        <address>first.last@[IPv6:::b4]</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>IPv6 authority is RFC 4291</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>236</id>
    </test>
    <test>
        <address>first.last@[IPv6::::b4]</address>
        <valid>false</valid>
        <warning>true</warning>
        <comment>IPv6 authority is RFC 4291</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>237</id>
    </test>
    <test>
        <address>first.last@[IPv6::b3:b4]</address>
        <valid>false</valid>
        <warning>true</warning>
        <comment>IPv6 authority is RFC 4291</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>238</id>
    </test>
    <test>
        <address>first.last@[IPv6:::b3:b4]</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>IPv6 authority is RFC 4291</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>239</id>
    </test>
    <test>
        <address>first.last@[IPv6::::b3:b4]</address>
        <valid>false</valid>
        <warning>true</warning>
        <comment>IPv6 authority is RFC 4291</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>240</id>
    </test>
    <test>
        <address>first.last@[IPv6:a1::b4]</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>IPv6 authority is RFC 4291</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>241</id>
    </test>
    <test>
        <address>first.last@[IPv6:a1:::b4]</address>
        <valid>false</valid>
        <warning>true</warning>
        <comment>IPv6 authority is RFC 4291</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>242</id>
    </test>
    <test>
        <address>first.last@[IPv6:a1:]</address>
        <valid>false</valid>
        <warning>true</warning>
        <comment>IPv6 authority is RFC 4291</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>243</id>
    </test>
    <test>
        <address>first.last@[IPv6:a1::]</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>IPv6 authority is RFC 4291</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>244</id>
    </test>
    <test>
        <address>first.last@[IPv6:a1:::]</address>
        <valid>false</valid>
        <warning>true</warning>
        <comment>IPv6 authority is RFC 4291</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>245</id>
    </test>
    <test>
        <address>first.last@[IPv6:a1:a2:]</address>
        <valid>false</valid>
        <warning>true</warning>
        <comment>IPv6 authority is RFC 4291</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>246</id>
    </test>
    <test>
        <address>first.last@[IPv6:a1:a2::]</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>IPv6 authority is RFC 4291</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>247</id>
    </test>
    <test>
        <address>first.last@[IPv6:a1:a2:::]</address>
        <valid>false</valid>
        <warning>true</warning>
        <comment>IPv6 authority is RFC 4291</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>248</id>
    </test>
    <test>
        <address>first.last@[IPv6:0123:4567:89ab:cdef::]</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>IPv6 authority is RFC 4291</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>249</id>
    </test>
    <test>
        <address>first.last@[IPv6:0123:4567:89ab:CDEF::]</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>IPv6 authority is RFC 4291</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>250</id>
    </test>
    <test>
        <address>first.last@[IPv6:::a3:a4:b1:ffff:11.22.33.44]</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>IPv6 authority is RFC 4291</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>251</id>
    </test>
    <test>
        <address>first.last@[IPv6:::a2:a3:a4:b1:ffff:11.22.33.44]</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>:: only elides one zero group (IPv6 authority is RFC 4291)</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>252</id>
    </test>
    <test>
        <address>first.last@[IPv6:a1:a2:a3:a4::11.22.33.44]</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>IPv6 authority is RFC 4291</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>253</id>
    </test>
    <test>
        <address>first.last@[IPv6:a1:a2:a3:a4:b1::11.22.33.44]</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>:: only elides one zero group (IPv6 authority is RFC 4291)</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>254</id>
    </test>
    <test>
        <address>first.last@[IPv6::11.22.33.44]</address>
        <valid>false</valid>
        <warning>true</warning>
        <comment>IPv6 authority is RFC 4291</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>255</id>
    </test>
    <test>
        <address>first.last@[IPv6::::11.22.33.44]</address>
        <valid>false</valid>
        <warning>true</warning>
        <comment>IPv6 authority is RFC 4291</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>256</id>
    </test>
    <test>
        <address>first.last@[IPv6:a1:11.22.33.44]</address>
        <valid>false</valid>
        <warning>true</warning>
        <comment>IPv6 authority is RFC 4291</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>257</id>
    </test>
    <test>
        <address>first.last@[IPv6:a1::11.22.33.44]</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>IPv6 authority is RFC 4291</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>258</id>
    </test>
    <test>
        <address>first.last@[IPv6:a1:::11.22.33.44]</address>
        <valid>false</valid>
        <warning>true</warning>
        <comment>IPv6 authority is RFC 4291</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>259</id>
    </test>
    <test>
        <address>first.last@[IPv6:a1:a2::11.22.33.44]</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>IPv6 authority is RFC 4291</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>260</id>
    </test>
    <test>
        <address>first.last@[IPv6:a1:a2:::11.22.33.44]</address>
        <valid>false</valid>
        <warning>true</warning>
        <comment>IPv6 authority is RFC 4291</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>261</id>
    </test>
    <test>
        <address>first.last@[IPv6:0123:4567:89ab:cdef::11.22.33.44]</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>IPv6 authority is RFC 4291</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>262</id>
    </test>
    <test>
        <address>first.last@[IPv6:0123:4567:89ab:cdef::11.22.33.xx]</address>
        <valid>false</valid>
        <warning>true</warning>
        <comment>IPv6 authority is RFC 4291</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>263</id>
    </test>
    <test>
        <address>first.last@[IPv6:0123:4567:89ab:CDEF::11.22.33.44]</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>IPv6 authority is RFC 4291</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>264</id>
    </test>
    <test>
        <address>first.last@[IPv6:0123:4567:89ab:CDEFF::11.22.33.44]</address>
        <valid>false</valid>
        <warning>true</warning>
        <comment>IPv6 authority is RFC 4291</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>265</id>
    </test>
    <test>
        <address>first.last@[IPv6:a1::a4:b1::b4:11.22.33.44]</address>
        <valid>false</valid>
        <warning>true</warning>
        <comment>IPv6 authority is RFC 4291</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>266</id>
    </test>
    <test>
        <address>first.last@[IPv6:a1::11.22.33]</address>
        <valid>false</valid>
        <warning>true</warning>
        <comment>IPv6 authority is RFC 4291</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>267</id>
    </test>
    <test>
        <address>first.last@[IPv6:a1::11.22.33.44.55]</address>
        <valid>false</valid>
        <warning>true</warning>
        <comment>IPv6 authority is RFC 4291</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>268</id>
    </test>
    <test>
        <address>first.last@[IPv6:a1::b211.22.33.44]</address>
        <valid>false</valid>
        <warning>true</warning>
        <comment>IPv6 authority is RFC 4291</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>269</id>
    </test>
    <test>
        <address>first.last@[IPv6:a1::b2:11.22.33.44]</address>
        <valid>true</valid>
        <warning>true</warning>
        <comment>IPv6 authority is RFC 4291</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>270</id>
    </test>
    <test>
        <address>first.last@[IPv6:a1::b2::11.22.33.44]</address>
        <valid>false</valid>
        <warning>true</warning>
        <comment>IPv6 authority is RFC 4291</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>271</id>
    </test>
    <test>
        <address>first.last@[IPv6:a1::b3:]</address>
        <valid>false</valid>
        <warning>true</warning>
        <comment>IPv6 authority is RFC 4291</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>272</id>
    </test>
    <test>
        <address>first.last@[IPv6::a2::b4]</address>
        <valid>false</valid>
        <warning>true</warning>
        <comment>IPv6 authority is RFC 4291</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>273</id>
    </test>
    <test>
        <address>first.last@[IPv6:a1:a2:a3:a4:b1:b2:b3:]</address>
        <valid>false</valid>
        <warning>true</warning>
        <comment>IPv6 authority is RFC 4291</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>274</id>
    </test>
    <test>
        <address>first.last@[IPv6::a2:a3:a4:b1:b2:b3:b4]</address>
        <valid>false</valid>
        <warning>true</warning>
        <comment>IPv6 authority is RFC 4291</comment>
        <source>Dominic Sayers</source>
        <sourcelink>http://www.dominicsayers.com/isemail</sourcelink>
        <id>275</id>
    </test>
</tests>
