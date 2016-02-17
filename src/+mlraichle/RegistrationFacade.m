classdef RegistrationFacade < mlfsl.RegistrationFacade
	%% REGISTRATIONFACADE  

	%  $Revision$
 	%  was created 15-Feb-2016 17:06:46
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.
 	

	properties
 		
 	end

	methods
        function g = pet(this)
            if (isempty(this.pet_))
                this.pet_ = mlpet.PETImagingContext( ...
                    this.annihilateEmptyCells({ this.oc(1) this.oc(2) this.ho(1) this.ho(2) this.oo(1) this.oo(2) this.fdg }));
            end
            g = this.pet_;
        end
        function g = fdg(this)
            if (isempty(this.fdg_) && ismethod(this.sessionData_, 'fdg'))
                this.fdg_ = this.sessionData_.fdg;
            end
            g = this.fdg_;
        end
        function g = gluc(this)
            g = [];
        end
        function g = ho(this, snum)
            assert(isnumeric(snum));
            %if (ismethod(this.sessionData_, 'ho') && ...
            %    isempty(this.ho_) && ...
            %    this.sessionData_.snumber ~= snum)
                this.sessionData_.snumber = snum;
                this.ho_ = this.sessionData_.ho;
            %end
            g = this.ho_;
        end
        function g = oo(this, snum)
            assert(isnumeric(snum));
            this.sessionData_.snumber = snum;
            this.oo_ = this.sessionData_.oo;
            g = this.oo_;
        end
        function g = oc(this, snum)
            assert(isnumeric(snum));
            this.sessionData_.snumber = snum;
            this.oc_ = this.sessionData_.oc;
            g = this.oc_;
        end
        function g = tr(this)
            g = [];
        end
        function prod = registerTalairachWithPet(this)
            %% REGISTERTALAIRACHWITHPET
            %  @return prod is a struct with products as fields.
            
            prod = this.initialTalairach;
            
            msrb = mlfsl.MultispectralRegistrationBuilder('sessionData', this.sessionData);
            msrb.sourceImage = prod.talairach;
            msrb.referenceImage = prod.petAtlas;
            msrb = msrb.registerSurjective;
            tal_on_atl = msrb.product;
            
            [oc1_on_atl,xfm_atl_on_oc1] = this.petRegisterAndInvertTransform(prod.oc1, prod.petAtlas);
            [oc2_on_atl,xfm_atl_on_oc2] = this.petRegisterAndInvertTransform(prod.oc2, prod.petAtlas);
            [ho1_on_atl,xfm_atl_on_ho1] = this.petRegisterAndInvertTransform(prod.ho1, prod.petAtlas);
            [ho2_on_atl,xfm_atl_on_ho2] = this.petRegisterAndInvertTransform(prod.ho2, prod.petAtlas);
            [oo1_on_atl,xfm_atl_on_oo1] = this.petRegisterAndInvertTransform(prod.oo1, prod.petAtlas);
            [oo2_on_atl,xfm_atl_on_oo2] = this.petRegisterAndInvertTransform(prod.oo2, prod.petAtlas);
            [fdg_on_atl,xfm_atl_on_fdg] = this.petRegisterAndInvertTransform(prod.fdg, prod.petAtlas);
            
            if (this.recursion)
                this.pet_ = mlpet.PETImagingContext( ...
                    this.annihilateEmptyCells({oc1_on_atl oc2_on_atl ho1_on_atl ho2_on_atl oo1_on_atl oo2_on_atl fdg_on_atl}));
            end
            
            prod.talairach_on_oc1 = this.transform(tal_on_atl, xfm_atl_on_oc1, prod.oc1);
            prod.talairach_on_oc2 = this.transform(tal_on_atl, xfm_atl_on_oc2, prod.oc2);
            prod.talairach_on_ho1 = this.transform(tal_on_atl, xfm_atl_on_ho1, prod.ho1);
            prod.talairach_on_ho2 = this.transform(tal_on_atl, xfm_atl_on_ho2, prod.ho2);
            prod.talairach_on_oo1 = this.transform(tal_on_atl, xfm_atl_on_oo1, prod.oo1);
            prod.talairach_on_oo2 = this.transform(tal_on_atl, xfm_atl_on_oo2, prod.oo2);
            prod.talairach_on_fdg = this.transform(tal_on_atl, xfm_atl_on_fdg, prod.fdg);
        end 
        function prod = initialTalairach(this)            
            prod.talairach = this.talairach;
            prod.petAtlas  = this.pet.atlas;
            prod.oc1       = this.oc(1);
            prod.oc2       = this.oc(2);
            prod.ho1       = this.petMotionCorrect(this.ho(1));
            prod.ho2       = this.petMotionCorrect(this.ho(2));
            prod.oo1       = this.petMotionCorrect(this.oo(1));
            prod.oo2       = this.petMotionCorrect(this.oo(2));
            prod.fdg       = this.petMotionCorrect(this.fdg);
        end
		  
 		function this = RegistrationFacade(varargin)
 			%% REGISTRATIONFACADE
 			%  Usage:  this = RegistrationFacade()

 			this = this@mlfsl.RegistrationFacade(varargin{:});
        end
        
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

