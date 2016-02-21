classdef RegistrationFacade < mlfsl.RegistrationFacade
	%% REGISTRATIONFACADE  

	%  $Revision$
 	%  was created 15-Feb-2016 17:06:46
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.
 	

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
        function product = registerTalairachWithPet(this)
            %% REGISTERTALAIRACHWITHPET
            %  @return product is a struct with products as fields.
            
            product = this.initialTalairachProduct;
            
            msrb = mlfsl.MultispectralRegistrationBuilder('sessionData', this.sessionData);
            msrb.sourceImage = product.talairach;
            msrb.referenceImage = product.petAtlas;
            msrb = msrb.registerSurjective;
            product.tal_on_atl = msrb.productuct;
            product.xfm_tal_on_atl = msrb.xfm;
            
            [oc1_on_atl,product.xfm_atl_on_oc1] = this.petRegisterAndInvertTransform(product.oc1, product.petAtlas);
            [oc2_on_atl,product.xfm_atl_on_oc2] = this.petRegisterAndInvertTransform(product.oc2, product.petAtlas);
            [ho1_on_atl,product.xfm_atl_on_ho1] = this.petRegisterAndInvertTransform(product.ho1, product.petAtlas);
            [ho2_on_atl,product.xfm_atl_on_ho2] = this.petRegisterAndInvertTransform(product.ho2, product.petAtlas);
            [oo1_on_atl,product.xfm_atl_on_oo1] = this.petRegisterAndInvertTransform(product.oo1, product.petAtlas);
            [oo2_on_atl,product.xfm_atl_on_oo2] = this.petRegisterAndInvertTransform(product.oo2, product.petAtlas);
            [fdg_on_atl,product.xfm_atl_on_fdg] = this.petRegisterAndInvertTransform(product.fdg, product.petAtlas);
            
            if (this.recursion)
                this.pet_ = mlpet.PETImagingContext( ...
                    this.annihilateEmptyCells( ...
                        {oc1_on_atl oc2_on_atl ho1_on_atl ho2_on_atl oo1_on_atl oo2_on_atl fdg_on_atl}));
            end
            
            product = this.finalTalairachProduct(product);
            save(this.checkpointFqfilename('registerTalairachWithPet'), 'product');
        end 
        function product = initialTalairachProduct(this)            
            product.talairach = this.talairach;
            product.oc1       = this.oc(1);
            product.oc2       = this.oc(2);
            product.ho1       = this.petMotionCorrect(this.ho(1));
            product.ho2       = this.petMotionCorrect(this.ho(2));
            product.oo1       = this.petMotionCorrect(this.oo(1));
            product.oo2       = this.petMotionCorrect(this.oo(2));
            product.fdg       = this.petMotionCorrect(this.fdg);
            
            pet = mlpet.PETImagingContext( ...
                    this.annihilateEmptyCells({ ...
                    product.oc1 product.oc2 product.ho1 product.ho2 product.oo1 product.oo2 product.fdg }));
            product.petAtlas = pet.atlas;
        end
        function product = finalTalairachProduct(this, product)    
            product.talairach_on_oc1 = this.transform(product.tal_on_atl, product.xfm_atl_on_oc1, product.oc1);
            product.talairach_on_oc2 = this.transform(product.tal_on_atl, product.xfm_atl_on_oc2, product.oc2);
            product.talairach_on_ho1 = this.transform(product.tal_on_atl, product.xfm_atl_on_ho1, product.ho1);
            product.talairach_on_ho2 = this.transform(product.tal_on_atl, product.xfm_atl_on_ho2, product.ho2);
            product.talairach_on_oo1 = this.transform(product.tal_on_atl, product.xfm_atl_on_oo1, product.oo1);
            product.talairach_on_oo2 = this.transform(product.tal_on_atl, product.xfm_atl_on_oo2, product.oo2);
            product.talairach_on_fdg = this.transform(product.tal_on_atl, product.xfm_atl_on_fdg, product.fdg);
        end
        function masks = masksTalairachProduct(this, msk, product)
            assert(all(msk.niftid.size == product.talairach.niftid.size));
            this.sessionData.ensureNIFTI_GZ(msk);
            
            t = 'transformNearestNeighbor';
            masks.talairach_on_atl = this.transform(msk,                    product.xfm_tal_on_atl, product.petAtlas, t);
            masks.talairach_on_oc1 = this.transform(masks.talairach_on_atl, product.xfm_atl_on_oc1, product.oc1, t);
            masks.talairach_on_oc2 = this.transform(masks.talairach_on_atl, product.xfm_atl_on_oc2, product.oc2, t);
            masks.talairach_on_ho1 = this.transform(masks.talairach_on_atl, product.xfm_atl_on_ho1, product.ho1, t);
            masks.talairach_on_ho2 = this.transform(masks.talairach_on_atl, product.xfm_atl_on_ho2, product.ho2, t);
            masks.talairach_on_oo1 = this.transform(masks.talairach_on_atl, product.xfm_atl_on_oo1, product.oo1, t);
            masks.talairach_on_oo2 = this.transform(masks.talairach_on_atl, product.xfm_atl_on_oo2, product.oo2, t);
            masks.talairach_on_fdg = this.transform(masks.talairach_on_atl, product.xfm_atl_on_fdg, product.fdg, t);
            save(this.checkpointFqfilename('masksTalairachProduct'), 'masks');
        end
		  
 		function this = RegistrationFacade(varargin)
 			%% REGISTRATIONFACADE
 			%  Usage:  this = RegistrationFacade()

 			this = this@mlfsl.RegistrationFacade(varargin{:});
        end
        
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

