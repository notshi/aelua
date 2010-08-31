
// some random javascript for use in hoe-house


//
// Add comma to a number every 3 digits, return string
// from http://www.merlyn.demon.co.uk/js-maths.htm
//
function comma3(SS)
  { var T='', S=String(SS), L=S.length-1, C, j, P = S.indexOf('.')-1
  if (P<0) P=L
  for (j=0; j<=L; j++) {
    T+=C=S.charAt(j)
    if ((j < P) && ((P-j)%3 == 0) && (C != '-')) T+=',' }
  return T }


//
// do the reverse of comma3
//
function comma3_to_number(ss)
{
	if(!ss) { return 0; }
	var s=String(ss);
	return parseInt(s.replace(/,/g,''),10);
}

