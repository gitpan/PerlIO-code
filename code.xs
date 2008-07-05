#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "perliol.h"

#include "ppport.h"

#define READING(fp, fail) do{\
		if( !(PerlIOBase(fp)->flags & PERLIO_F_CANREAD) ) return (fail);\
	} while(0)
#define WRITING(fp, fail) do{\
		if( !(PerlIOBase(fp)->flags & PERLIO_F_CANWRITE)) return (fail);\
		PerlIOBase(fp)->flags &= ~PERLIO_F_RDBUF;\
	} while(0)

#define IOC(f) (PerlIOSelf((f), PerlIOCode))


typedef struct{
	struct _PerlIO base;
	CV* cv;

	SV* buf;
	Off_t offset;
} PerlIOCode;

IV
PerlIOCode_pushed(pTHX_ PerlIO * f, const char *mode, SV * arg, PerlIO_funcs * tab){
	PerlIOCode* ioc = IOC(f);
	IV cv;

	if(arg){
		HV* stash;
		GV* gv;
		ioc->cv = sv_2cv(arg, &stash, &gv, TRUE);

		if(!ioc->cv){
			return -1;
		}

		SvREFCNT_inc_simple_void_NN(ioc->cv);
	}
	else{
		return -1; /* fail */
	}

	ioc->buf = newSVpvs("");
	ioc->offset = 0;

	return PerlIOBase_pushed(aTHX_ f, mode, Nullsv, tab);
}
IV
PerlIOCode_popped(pTHX_ PerlIO * f){
	PerlIOCode *ioc = IOC(f);
	if (ioc->cv) {
		SvREFCNT_dec(ioc->cv);
		ioc->cv = Nullcv;
	}
	if(ioc->buf){
		SvREFCNT_dec(ioc->buf);
		ioc->buf = Nullsv;
	}
	return PerlIOBase_popped(aTHX_ f);
}

PerlIO*
PerlIOCode_open(pTHX_ PerlIO_funcs *tab,
			PerlIO_list_t *layers, IV n, const char *mode,
			int fd, int imode, int perm,
			PerlIO *f, int narg, SV **args){
	SV* arg = (narg > 0) ? args[0] : PerlIOArg;

	if(f){
		PerlIO_close(f);
	}
	else{
		f = PerlIO_allocate(aTHX);
	}

	if ( (f = PerlIO_push(aTHX_ f, tab, mode, arg)) ) {
		PerlIOBase(f)->flags |= PERLIO_F_OPEN;
	}
	return f;
}

SSize_t
PerlIOCode_write(pTHX_ PerlIO *f, const void *vbuf, Size_t count){
	PerlIOCode* ioc = IOC(f);
	dSP;

	WRITING(f, -1);

	PUSHMARK(SP);
	sv_setpvn(ioc->buf, vbuf, count);
	XPUSHs(ioc->buf);
	PUTBACK;

	call_sv((SV*)ioc->cv, G_VOID | G_DISCARD);

	return count;
}

IV
PerlIOCode_fill(pTHX_ PerlIO* f){
	dSP;
	PerlIOCode* ioc = IOC(f);
	SV* result;

	READING(f, -1);

	if(PerlIOBase(f)->flags & PERLIO_F_EOF){
		return -1;
	}

	
	ENTER;
	//SAVETMPS;

	PUSHMARK(SP);

	if(call_sv((SV*)ioc->cv, G_SCALAR) != 1){
		Perl_croak(aTHX_ "the callback did not return a value");
	}

	SPAGAIN;

	result = POPs;

	if(SvOK(result)){
		sv_copypv(ioc->buf, result);
		PerlIOBase(f)->flags |= PERLIO_F_RDBUF;
	}
	else{
		PerlIOBase(f)->flags |= PERLIO_F_EOF;
		sv_setpvn(ioc->buf, "", 0);
	}

	ioc->offset = 0;

	PUTBACK;
	//FREETMPS;
	LEAVE;

	return SvCUR(ioc->buf) ? 0 : -1;
}

STDCHAR*
PerlIOCode_get_base(pTHX_ PerlIO* f){
	return (STDCHAR*)SvPV_nolen(IOC(f)->buf);
}
Size_t
PerlIOCode_bufsiz(pTHX_ PerlIO* f){
	return SvCUR(IOC(f)->buf);
}

STDCHAR*
PerlIOCode_get_ptr(pTHX_ PerlIO* f){
	return (STDCHAR*)SvPV_nolen(IOC(f)->buf) + IOC(f)->offset;
}

SSize_t
PerlIOCode_get_cnt(pTHX_ PerlIO* f){
	return SvCUR(IOC(f)->buf) - IOC(f)->offset;
}

void
PerlIOCode_set_ptrcnt(pTHX_ PerlIO* f, STDCHAR* ptr, SSize_t cnt){
	IOC(f)->offset = SvCUR(IOC(f)->buf) - cnt;
}

PERLIO_FUNCS_DECL(PerlIO_code) = {
	sizeof(PerlIO_funcs),
	"Code",
	sizeof(PerlIOCode),
	PERLIO_K_BUFFERED, /* kind */
	PerlIOCode_pushed,
	PerlIOCode_popped,
	PerlIOCode_open,
	PerlIOBase_binmode,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	PerlIOCode_write,
	NULL,
	NULL,
	NULL,
	NULL,
	PerlIOCode_fill,
	NULL,
	NULL,
	NULL,
	NULL,
	PerlIOCode_get_base,
	PerlIOCode_bufsiz,
	PerlIOCode_get_ptr,
	PerlIOCode_get_cnt,
	PerlIOCode_set_ptrcnt
};


MODULE = PerlIO::code		PACKAGE = PerlIO::code		

PROTOTYPES: DISABLE

BOOT:
	PerlIO_define_layer(aTHX_ PERLIO_FUNCS_CAST(&PerlIO_code));
