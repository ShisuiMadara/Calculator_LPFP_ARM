<h1>About LPFP format</h1>
LPFP format is a Low Precision Floating Point representation of data. Generally its 8 bit or 12 bit but this one is for 32 bits. 
The format has many advantages over the IEEE 756 format:
<li>
It is smaller in size</li>
<li>Smaller size means less bits to be operated, hece the operations are faster</li>
<li>If the exponent size is increase to more the of the IEEE this means more precision</li>
<li>For its smaller in size, it occupies less space and thus provides more space for other instructions
</li>

<h1>About this project</h1>
<p>The mantissa is 16 bits and the exponent term spans 15 bits and 1 bit is a signed bit. Thus its different from conventional LPFP format which had smaller number of bits. </p>
The operation performed under the name of addition and multipication but since the negetive number and fraction are also covered,
the program works for substraction (addition of positive and negetive) and division (multiplication of integer and a fraction).
The input is in normal hexadeciaml format which is converted to our defined format inside our code itself. 

The code worked fine (<em>On my machine </em>) :)
